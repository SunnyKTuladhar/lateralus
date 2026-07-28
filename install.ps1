# lateralus — install script (PowerShell 5.1+)
#
# Copies lateralus skills and agents into your Claude Code config directory.
#
# One-line install:
#   irm https://raw.githubusercontent.com/SunnyKTuladhar/lateralus/main/install.ps1 | iex
#
# Local clone:
#   .\install.ps1

$ErrorActionPreference = "Stop"

$Repo   = "SunnyKTuladhar/lateralus"
$Branch = "main"
$Raw    = "https://raw.githubusercontent.com/$Repo/$Branch"
$ClaudeDir = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } `
             else { Join-Path $HOME ".claude" }

$Skills = @(
  "skills/lateralus/SKILL.md:lateralus",
  "skills/lateralus-brainstorm/SKILL.md:lateralus-brainstorm"
)
$Agents = @(
  "agents/lateralus-ideator-ground.md",
  "agents/lateralus-ideator-balanced.md",
  "agents/lateralus-ideator-wild.md",
  "agents/lateralus-workaround.md"
)
$Hooks = @(
  "hooks/lateralus-hook.ps1"
)

Write-Host "Installing lateralus -> $ClaudeDir"

$Here = Split-Path -Parent $MyInvocation.MyCommand.Path

function Copy-Asset($RelPath, $DestDir) {
  $null = New-Item -ItemType Directory -Force -Path $DestDir
  $Local = Join-Path $Here $RelPath.Replace("/", [IO.Path]::DirectorySeparatorChar)
  $Dest  = Join-Path $DestDir (Split-Path -Leaf $RelPath)
  if (Test-Path $Local) {
    Copy-Item $Local $Dest -Force
  } else {
    Invoke-WebRequest "$Raw/$RelPath" -OutFile $Dest -UseBasicParsing
  }
}

foreach ($s in $Skills) {
  $parts    = $s -split ":"
  $skillSrc = $parts[0]
  $skillName = $parts[1]
  $destDir  = Join-Path $ClaudeDir "skills\$skillName"
  $null = New-Item -ItemType Directory -Force -Path $destDir
  $Local = Join-Path $Here $skillSrc.Replace("/", [IO.Path]::DirectorySeparatorChar)
  $Dest  = Join-Path $destDir "SKILL.md"
  if (Test-Path $Local) {
    Copy-Item $Local $Dest -Force
  } else {
    Invoke-WebRequest "$Raw/$skillSrc" -OutFile $Dest -UseBasicParsing
  }
  Write-Host "  v skill: $skillName"
}

foreach ($a in $Agents) {
  Copy-Asset $a (Join-Path $ClaudeDir "agents")
  Write-Host "  v agent: $(Split-Path -Leaf $a)"
}

# Install hook
foreach ($h in $Hooks) {
  Copy-Asset $h (Join-Path $ClaudeDir "hooks")
  Write-Host "  v hook:  $(Split-Path -Leaf $h)"
}

# Wire hook into ~/.claude/settings.json (idempotent)
# Requires pwsh (PowerShell 6+) for -AsHashtable support — skips gracefully if unavailable
$Settings = Join-Path $ClaudeDir "settings.json"
$PwshCmd  = Get-Command pwsh -ErrorAction SilentlyContinue

if (-not $PwshCmd -or $PSVersionTable.PSVersion.Major -lt 6) {
    Write-Host "  ! PowerShell 6+ (pwsh) required for hook wiring — skipping."
    Write-Host "    Install pwsh and re-run, or wire the hook manually:"
    Write-Host "    https://github.com/SunnyKTuladhar/lateralus#manual-hook-wiring"
} else {
    $HookCmd = "pwsh -NonInteractive -File `"$(Join-Path $ClaudeDir 'hooks\lateralus-hook.ps1')`""

    $cfg = @{}
    $parseFailed = $false
    if (Test-Path $Settings) {
        $raw = (Get-Content $Settings -Raw) -replace '(?m)^\s*//.*$', ''
        try {
            $cfg = $raw | ConvertFrom-Json -AsHashtable
        } catch {
            $parseFailed = $true
        }
    }

    if ($parseFailed) {
        Write-Host "  ! Could not parse $Settings — skipping hook wiring."
        Write-Host "    Wire the hook manually: https://github.com/SunnyKTuladhar/lateralus#manual-hook-wiring"
    } else {
        if (-not $cfg.ContainsKey("hooks"))                { $cfg["hooks"] = @{} }
        if (-not $cfg["hooks"].ContainsKey("PostToolUse")) { $cfg["hooks"]["PostToolUse"] = @() }

        $alreadyWired = $cfg["hooks"]["PostToolUse"] | ForEach-Object {
            if ($_ -is [hashtable] -and $_.hooks) {
                $_.hooks | Where-Object { $_ -is [hashtable] -and $_.command -eq $HookCmd }
            }
        } | Select-Object -First 1

        if (-not $alreadyWired) {
            $cfg["hooks"]["PostToolUse"] += @{
                matcher = "Edit|Write|Create|MultiEdit|NotebookEditCell|Bash"
                hooks   = @(@{ type = "command"; command = $HookCmd })
            }
        }

        $null = New-Item -ItemType Directory -Force -Path $ClaudeDir
        if (Test-Path $Settings) { Copy-Item $Settings "$Settings.bak" -Force }
        $cfg | ConvertTo-Json -Depth 10 | Set-Content $Settings -Encoding UTF8
        Write-Host "  v hook wired in: $Settings"
    }
}

Write-Host ""
Write-Host "Done. Open Claude Code and type /lateralus to use."
Write-Host "For workarounds: /lateralus-workaround"
Write-Host ""
Write-Host "Hook: lateralus-hook.ps1 fires on every Bash tool call and nudges /lateralus when"
Write-Host "      a failure signature recurs after edits. Set LATERALUS_THRESHOLD to adjust sensitivity."
