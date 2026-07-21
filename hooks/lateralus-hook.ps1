#Requires -Version 5.1
<#
.SYNOPSIS
    lateralus PostToolUse hook (Windows / PowerShell).
    Equivalent of lateralus-hook.py for environments where Python3 is unavailable.

.DESCRIPTION
    Fires after every Claude Code tool call. Tracks failure signatures across
    edit attempts and nudges the lateralus skill when the same root failure
    recurs — converting "did the agent notice it's stalled?" into a deterministic
    counter crossing a threshold.

    State file: $HOME\.claude\lateralus-state.json (keyed by session_id)
    Threshold:  LATERALUS_THRESHOLD env var, default 2
#>

$ErrorActionPreference = "Stop"

$Threshold = if ($env:LATERALUS_THRESHOLD) { [int]$env:LATERALUS_THRESHOLD } else { 2 }
$ClaudeDir = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME ".claude" }
$StateFile = Join-Path $ClaudeDir "lateralus-state.json"
$SessionTtlHours = 24  # prune sessions not seen within this window

$EditTools = @("Edit", "Write", "Create", "MultiEdit", "NotebookEditCell")
$BashTools  = @("Bash")
# Known limitation: failures via MCP or custom lint tools are not tracked.

# ── Signature normalization ────────────────────────────────────────────────────

function Get-Signature([string]$Text) {
    # Use last 30 lines, not first 20.
    # JVM/PySpark/Py4J tracebacks bury the real exception at the bottom.
    $lines = ($Text -split "`n")
    $lines = if ($lines.Count -gt 30) { $lines[-30..-1] } else { $lines }
    $lines = $lines -join "`n"

    # Line numbers
    $lines = $lines -replace ':\d+:', ':N:'
    $lines = $lines -replace '\bline \d+\b', 'line N'
    $lines = $lines -replace '\bL\d+\b', 'LN'
    $lines = $lines -replace '#\d+\b', '#N'

    # Absolute paths — keep basename
    $lines = $lines -replace '(?:/[^\s:\"''()\[\]]+/)+([^\s:/\"''()\[\]]+)', '<path>/$1'
    $lines = $lines -replace '(?:[A-Za-z]:\\[^\s:\"''()\[\]]+\\)+([^\s:\\\"''()\[\]]+)', '<path>/$1'

    # Timestamps
    $lines = $lines -replace '\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:?\d{2})?', '<ts>'
    $lines = $lines -replace '\b\d{2}:\d{2}:\d{2}(?:\.\d+)?\b', '<ts>'

    # Hex addresses and hashes
    $lines = $lines -replace '\b0x[0-9a-fA-F]{4,}\b', '<addr>'
    $lines = $lines -replace '\b[0-9a-f]{7,64}\b', '<hash>'

    # PIDs/ports
    $lines = $lines -replace '(?i)\bpid[= ]\d+\b', 'pid=N'
    $lines = $lines -replace '(?i)\bport[= ]\d+\b', 'port=N'

    # Collapse whitespace
    $lines = $lines -replace '[ \t]+', ' '
    $lines = $lines -replace '\n{3,}', "`n`n"
    $lines = $lines.Trim()

    $bytes  = [System.Text.Encoding]::UTF8.GetBytes($lines)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $hash   = $sha256.ComputeHash($bytes)
    return ([System.BitConverter]::ToString($hash) -replace '-').ToLower().Substring(0, 12)
}

# ── State helpers ──────────────────────────────────────────────────────────────

function Get-State {
    if (Test-Path $StateFile) {
        try { return Get-Content $StateFile -Raw | ConvertFrom-Json -AsHashtable }
        catch {}
    }
    return @{}
}

function Save-State($State) {
    # Prune sessions not active in the last $SessionTtlHours to keep the file bounded.
    $cutoff = (Get-Date).ToUniversalTime().AddHours(-$SessionTtlHours)
    $pruned = @{}
    foreach ($sid in $State.Keys) {
        $sdata = $State[$sid]
        $sigs  = if ($sdata.ContainsKey("signatures")) { $sdata["signatures"] } else { @{} }
        $keep  = $false
        foreach ($sd in $sigs.Values) {
            if ($sd["last_seen"]) {
                try {
                    $ts = [datetime]::Parse($sd["last_seen"]).ToUniversalTime()
                    if ($ts -gt $cutoff) { $keep = $true; break }
                } catch {}
            }
        }
        if ($keep -or $sigs.Count -eq 0) { $pruned[$sid] = $sdata }
    }
    $null = New-Item -ItemType Directory -Force -Path $ClaudeDir
    $pruned | ConvertTo-Json -Depth 10 | Set-Content $StateFile -Encoding UTF8
}

# ── Main ───────────────────────────────────────────────────────────────────────

try {
    $Input    = $input | Out-String
    $Event    = $Input | ConvertFrom-Json -AsHashtable
} catch {
    exit 0
}

$SessionId = if ($Event.session_id) { $Event.session_id } else { "unknown" }
$ToolName  = if ($Event.tool_name)  { $Event.tool_name  } else { "" }

$State   = Get-State
if (-not $State.ContainsKey($SessionId)) { $State[$SessionId] = @{ signatures = @{} } }
$Session = $State[$SessionId]
if (-not $Session.ContainsKey("signatures")) { $Session["signatures"] = @{} }

# Edit/Write/Create: mark genuine fix attempt
if ($EditTools -contains $ToolName) {
    foreach ($k in @($Session["signatures"].Keys)) {
        $Session["signatures"][$k]["edit_since_last"] = $true
    }
    Save-State $State
    exit 0
}

# Non-Bash tools: pass through
if ($BashTools -notcontains $ToolName) { exit 0 }

$Response = $Event["tool_response"]
if ($Response -isnot [hashtable]) { exit 0 }

$ExitCode = if ($Response.exit_code) { [int]$Response.exit_code } else { 0 }

# Success: clear failure state
if ($ExitCode -eq 0) {
    $Session["signatures"] = @{}
    Save-State $State
    exit 0
}

# Failure: extract error text
$Stderr    = if ($Response.stderr) { $Response.stderr.Trim() } else { "" }
$Stdout    = if ($Response.stdout) { $Response.stdout.Trim() } else { "" }
$ErrorText = if ($Stderr) { $Stderr } else { $Stdout }

if (-not $ErrorText) { exit 0 }

$Sig     = Get-Signature $ErrorText
$Sigs    = $Session["signatures"]
if (-not $Sigs.ContainsKey($Sig)) {
    $Sigs[$Sig] = @{ count = 0; edit_since_last = $false }
}
$SigData = $Sigs[$Sig]

$Now     = (Get-Date).ToUniversalTime()
$Cutoff  = $Now.AddHours(-$SessionTtlHours)

$LastSeen = $null
try {
    if ($SigData["last_seen"]) {
        $LastSeen = [datetime]::Parse($SigData["last_seen"]).ToUniversalTime()
    }
} catch {}

$Stale = $LastSeen -and ($LastSeen -lt $Cutoff)

if ($SigData["count"] -eq 0 -or $SigData["edit_since_last"] -or $Stale) {
    if ($Stale) {
        $SigData["count"] = 1  # reset — different stall window
    } else {
        $SigData["count"] += 1
    }
    $SigData["edit_since_last"] = $false
    $SigData["last_seen"]       = $Now.ToString("o")
}

$Count = $SigData["count"]
Save-State $State

if ($Count -ge $Threshold) {
    [Console]::Error.WriteLine(
        "[lateralus] Failure signature '$Sig' has recurred ${Count}x after edit attempts " +
        "— this loop is stalled. Invoke the lateralus skill before making another fix attempt."
    )
    exit 2
}

exit 0
