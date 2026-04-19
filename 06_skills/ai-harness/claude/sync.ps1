<#
.SYNOPSIS
  Install / update justin_lin's Claude skills and agents into ~/.claude/.

.DESCRIPTION
  Windows equivalent of sync.sh.
  Default mode is symlink — edits in this repo take effect immediately,
  no need to re-run after every change.

  Symlinks on Windows require either Developer Mode enabled or an
  elevated (Administrator) terminal.

.PARAMETER Copy
  Snapshot copy with Copy-Item instead of symlink.

.PARAMETER DryRun
  Print what would happen, change nothing.

.PARAMETER Uninstall
  Remove only the items this script installed.

.EXAMPLE
  .\sync.ps1              # symlink skills + agents (default, idempotent)
  .\sync.ps1 -Copy        # snapshot copy
  .\sync.ps1 -DryRun      # print what would happen
  .\sync.ps1 -Uninstall   # remove installed items

.NOTES
  Conflict handling:
    - Existing symlinks are replaced silently.
    - Existing real directories or files are NOT clobbered. The script
      reports them and skips, so other people's items (or hand-edited
      copies) are never destroyed.
#>

[CmdletBinding()]
param(
    [switch]$Copy,
    [switch]$DryRun,
    [switch]$Uninstall
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Mode = if ($Copy) { 'copy' } else { 'symlink' }

# Resolve source dirs relative to this script.
$ScriptDir  = $PSScriptRoot
$SkillsSrc  = Join-Path $ScriptDir 'skills'
$AgentsSrc  = Join-Path $ScriptDir 'agents'
$CommandsSrc = Join-Path $ScriptDir 'commands'
$StatuslineSrc  = Join-Path (Join-Path $ScriptDir 'statusline') 'statusline-command.sh'
$ClaudeHome     = Join-Path $env:USERPROFILE '.claude'
$SkillsDest     = Join-Path $ClaudeHome 'skills'
$AgentsDest     = Join-Path $ClaudeHome 'agents'
$CommandsDest   = Join-Path $ClaudeHome 'commands'
$StatuslineDest = Join-Path $ClaudeHome 'statusline-command.sh'

# --- Collect items ---

# Skills: any directory under skills/ that contains SKILL.md
$Skills = @()
if (Test-Path $SkillsSrc -PathType Container) {
    Get-ChildItem -Path $SkillsSrc -Directory | ForEach-Object {
        if (Test-Path (Join-Path $_.FullName 'SKILL.md')) {
            $Skills += $_.Name
        }
    }
}

# Agents: *.md files under agents/
$Agents = @()
if (Test-Path $AgentsSrc -PathType Container) {
    Get-ChildItem -Path $AgentsSrc -Filter '*.md' -File | ForEach-Object {
        $Agents += $_.Name
    }
}

# Slash commands: *.md files under commands/
$Commands = @()
if (Test-Path $CommandsSrc -PathType Container) {
    Get-ChildItem -Path $CommandsSrc -Filter '*.md' -File | ForEach-Object {
        $Commands += $_.Name
    }
}

if ($Skills.Count -eq 0 -and $Agents.Count -eq 0 -and $Commands.Count -eq 0 -and -not (Test-Path $StatuslineSrc)) {
    Write-Error 'nothing to install — no skills, agents, commands, or statusline found'
    exit 1
}

# --- Helpers ---

function Test-Symlink {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $false }
    $item = Get-Item $Path -Force
    return [bool]($item.Attributes -band [IO.FileAttributes]::ReparsePoint)
}

function Invoke-Run {
    param([string]$Description, [scriptblock]$Action)
    if ($DryRun) {
        Write-Host "DRY: $Description"
    } else {
        & $Action
    }
}

function Ensure-Dir {
    param([string]$Path)
    if (-not (Test-Path $Path -PathType Container)) {
        Invoke-Run "mkdir $Path" { New-Item -Path $Path -ItemType Directory -Force | Out-Null }
    }
}

function Uninstall-One {
    param([string]$Target)
    if (Test-Symlink $Target) {
        Invoke-Run "rm $Target" {
            $item = Get-Item $Target -Force
            if ($item.PSIsContainer) {
                $item.Delete()
            } else {
                Remove-Item $Target -Force
            }
        }
        Write-Host "removed symlink: $Target"
    } elseif (Test-Path $Target) {
        Write-Host "skip (not a symlink, leaving alone): $Target"
    }
}

function Install-One {
    param([string]$Src, [string]$Target)

    # Existing symlink — safe to replace.
    if (Test-Symlink $Target) {
        Invoke-Run "rm $Target" {
            $item = Get-Item $Target -Force
            if ($item.PSIsContainer) {
                $item.Delete()
            } else {
                Remove-Item $Target -Force
            }
        }
    }
    # Existing real dir/file — refuse to clobber.
    elseif (Test-Path $Target) {
        Write-Host "skip (exists, not a symlink — refusing to clobber): $Target"
        return
    }

    if ($Mode -eq 'symlink') {
        Invoke-Run "link $Target -> $Src" {
            New-Item -ItemType SymbolicLink -Path $Target -Target $Src -Force | Out-Null
        }
        Write-Host "linked: $Target -> $Src"
    } else {
        Invoke-Run "copy $Src -> $Target" {
            if (Test-Path $Src -PathType Container) {
                Copy-Item -Path $Src -Destination $Target -Recurse -Force
            } else {
                Copy-Item -Path $Src -Destination $Target -Force
            }
        }
        Write-Host "copied: $Target"
    }
}

# --- Uninstall mode ---
if ($Uninstall) {
    foreach ($name in $Skills)   { Uninstall-One (Join-Path $SkillsDest $name) }
    foreach ($name in $Agents)   { Uninstall-One (Join-Path $AgentsDest $name) }
    foreach ($name in $Commands) { Uninstall-One (Join-Path $CommandsDest $name) }
    Uninstall-One $StatuslineDest
    exit 0
}

# --- Install mode ---
Write-Host "mode: $Mode"
Write-Host ''

# Skills
if ($Skills.Count -gt 0) {
    Ensure-Dir $SkillsDest
    Write-Host "skills: $SkillsSrc -> $SkillsDest"
    foreach ($name in $Skills) {
        Install-One (Join-Path $SkillsSrc $name) (Join-Path $SkillsDest $name)
    }
    Write-Host ''
}

# Agents
if ($Agents.Count -gt 0) {
    Ensure-Dir $AgentsDest
    Write-Host "agents: $AgentsSrc -> $AgentsDest"
    foreach ($name in $Agents) {
        Install-One (Join-Path $AgentsSrc $name) (Join-Path $AgentsDest $name)
    }
    Write-Host ''
}

# Slash commands
if ($Commands.Count -gt 0) {
    Ensure-Dir $CommandsDest
    Write-Host "commands: $CommandsSrc -> $CommandsDest"
    foreach ($name in $Commands) {
        Install-One (Join-Path $CommandsSrc $name) (Join-Path $CommandsDest $name)
    }
    Write-Host ''
}

# Statusline
$StatuslineInstalled = 0
if (Test-Path $StatuslineSrc) {
    Ensure-Dir $ClaudeHome
    Write-Host "statusline: $StatuslineSrc -> $StatuslineDest"
    Install-One $StatuslineSrc $StatuslineDest
    $StatuslineInstalled = 1
    Write-Host ''
}

$total = $Skills.Count + $Agents.Count + $Commands.Count + $StatuslineInstalled
Write-Host "done. installed $total item(s):"
foreach ($name in $Skills)   { Write-Host "  skill: $name" }
foreach ($name in $Agents)   { Write-Host "  agent: $name" }
foreach ($name in $Commands) { Write-Host "  command: $name" }
if ($StatuslineInstalled -eq 1) {
    Write-Host "  statusline: $StatuslineDest"
}