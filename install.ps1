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
  "skills/lateralus/SKILL.md",
  "skills/lateralus-caveman/SKILL.md"
)
$Agents = @(
  "agents/lateralus-ideator-ground.md",
  "agents/lateralus-ideator-balanced.md",
  "agents/lateralus-ideator-wild.md",
  "agents/lateralus-workaround.md"
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
  $name = Split-Path -Leaf (Split-Path -Parent $s)
  Copy-Asset $s (Join-Path $ClaudeDir "skills\$name")
  Write-Host "  v skill: $name"
}

foreach ($a in $Agents) {
  Copy-Asset $a (Join-Path $ClaudeDir "agents")
  Write-Host "  v agent: $(Split-Path -Leaf $a)"
}

Write-Host ""
Write-Host "Done. Open Claude Code and type /lateralus to use."
Write-Host "For workarounds: /lateralus-workaround"
Write-Host "For compressed mode: /lateralus-caveman"
