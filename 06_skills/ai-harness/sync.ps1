<#
.SYNOPSIS
  Sync Claude, Codex, and Copilot harnesses in one shot.

.DESCRIPTION
  Windows equivalent of sync.sh.
  Treats this repo as the source of truth, replacing same-name installed items.

.PARAMETER Copy
  Pass through to child scripts — snapshot copy instead of symlink.

.PARAMETER DryRun
  Pass through to child scripts — print what would happen, change nothing.

.PARAMETER Uninstall
  Pass through to child scripts — remove only installed items.

.PARAMETER ClaudeOnly
  Sync only the Claude harness.

.PARAMETER CodexOnly
  Sync only the Codex harness.

.PARAMETER CopilotOnly
  Sync only the Copilot harness.

.EXAMPLE
  .\sync.ps1                  # sync Claude, Codex, and Copilot
  .\sync.ps1 -DryRun          # pass through to all child scripts
  .\sync.ps1 -Copy            # snapshot copy mode
  .\sync.ps1 -Uninstall       # remove installed items
  .\sync.ps1 -ClaudeOnly      # sync only Claude
  .\sync.ps1 -CodexOnly       # sync only Codex
  .\sync.ps1 -CopilotOnly     # sync only Copilot
#>

[CmdletBinding()]
param(
    [switch]$Copy,
    [switch]$DryRun,
    [switch]$Uninstall,
    [switch]$ClaudeOnly,
    [switch]$CodexOnly,
    [switch]$CopilotOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($ClaudeOnly -and $CodexOnly) {
    Write-Error 'cannot combine -ClaudeOnly with -CodexOnly'
    exit 2
}
if ($ClaudeOnly -and $CopilotOnly) {
    Write-Error 'cannot combine -ClaudeOnly with -CopilotOnly'
    exit 2
}
if ($CodexOnly -and $CopilotOnly) {
    Write-Error 'cannot combine -CodexOnly with -CopilotOnly'
    exit 2
}

$ScriptDir = $PSScriptRoot

# Build passthrough parameters for child scripts.
$Passthrough = @{}
if ($Copy)      { $Passthrough['Copy']      = $true }
if ($DryRun)    { $Passthrough['DryRun']    = $true }
if ($Uninstall) { $Passthrough['Uninstall'] = $true }

function Invoke-Target {
    param([string]$Target)
    $script = Join-Path $ScriptDir "$Target\sync.ps1"
    if (-not (Test-Path $script)) {
        Write-Error "missing child sync script: $script"
        exit 1
    }
    Write-Host "==> $Target"
    & $script @Passthrough
    Write-Host ''
}

if ($ClaudeOnly) {
    Invoke-Target 'claude'
} elseif ($CodexOnly) {
    Invoke-Target 'codex'
} elseif ($CopilotOnly) {
    Invoke-Target 'copilot'
} else {
    Invoke-Target 'claude'
    Invoke-Target 'codex'
    Invoke-Target 'copilot'
}
