<#
.SYNOPSIS
  Install / update justin_lin's Codex harness into ~/.codex/.

.DESCRIPTION
  Windows equivalent of sync.sh.
  Default mode is symlink, so edits in this repo take effect immediately.

  Symlinks on Windows require either Developer Mode enabled or an
  elevated (Administrator) terminal.

.PARAMETER Copy
  Snapshot copy with Copy-Item instead of symlink.

.PARAMETER DryRun
  Print what would happen, change nothing.

.PARAMETER Uninstall
  Remove only the items this script installed.

.EXAMPLE
  .\sync.ps1              # symlink skills + agents + hooks + audio (default, idempotent)
  .\sync.ps1 -Copy        # snapshot copy
  .\sync.ps1 -DryRun      # print what would happen
  .\sync.ps1 -Uninstall   # remove installed items

.NOTES
  Conflict handling:
    - If the same name already exists, leave it alone and skip installation.
    - If the existing entry is already linked to this repo, skip as a no-op.
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
$ScriptDir      = $PSScriptRoot
$SkillsSrc      = Join-Path $ScriptDir 'skills'
$AgentsSrc      = Join-Path $ScriptDir 'agents'
$HooksSrc       = Join-Path $ScriptDir '..\claude\hooks'
$AudioSrc       = Join-Path $ScriptDir '..\audio'
$ConfigMergeScript = Join-Path $ScriptDir 'scripts\merge-config.mjs'
$HooksMergeScript  = Join-Path $ScriptDir 'scripts\merge-hooks.mjs'
$CodexHome      = Join-Path $env:USERPROFILE '.codex'
$SkillsDest     = Join-Path $CodexHome 'skills'
$AgentsDest     = Join-Path $CodexHome 'agents'
$HooksDest      = Join-Path $CodexHome 'hooks'
$AudioDest      = Join-Path $CodexHome 'audio'
$ConfigDest     = Join-Path $CodexHome 'config.toml'
$HooksJsonDest  = Join-Path $CodexHome 'hooks.json'
$NodePathDest   = Join-Path $CodexHome 'ai-harness-node-path.txt'

# Resolve relative paths for display
foreach ($var in 'HooksSrc', 'AudioSrc') {
    $raw = Get-Variable $var -ValueOnly
    try {
        $resolved = Resolve-Path -LiteralPath $raw -ErrorAction SilentlyContinue
        if ($resolved) { Set-Variable $var $resolved.Path }
    } catch {}
}

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

# Hooks: *.mjs / *.ps1 files under hooks/
$HookFiles = @()
if (Test-Path $HooksSrc -PathType Container) {
    Get-ChildItem -Path $HooksSrc -File | Where-Object { $_.Extension -in '.mjs', '.ps1' } | ForEach-Object {
        $HookFiles += $_.Name
    }
}

# Audio: *.mp3 files under ../audio/
$AudioFiles = @()
if (Test-Path $AudioSrc -PathType Container) {
    Get-ChildItem -Path $AudioSrc -Filter '*.mp3' -File | ForEach-Object {
        $AudioFiles += $_.Name
    }
}

if ($Skills.Count -eq 0 -and $Agents.Count -eq 0 `
    -and $HookFiles.Count -eq 0 -and $AudioFiles.Count -eq 0 `
    -and -not (Test-Path $ConfigMergeScript) -and -not (Test-Path $HooksMergeScript)) {
    Write-Error 'nothing to install - no skills, agents, hooks, audio, or codex config helpers found'
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

function Resolve-NodeBin {
    if ($env:AI_HARNESS_NODE_BIN -and (Test-Path $env:AI_HARNESS_NODE_BIN)) {
        return (Resolve-Path -LiteralPath $env:AI_HARNESS_NODE_BIN).Path
    }

    try {
        return (Get-Command node -ErrorAction Stop).Source
    } catch {}

    foreach ($candidate in @(
        (Join-Path $env:USERPROFILE '.volta\bin\node.exe'),
        'C:\Program Files\nodejs\node.exe',
        'C:\Program Files (x86)\nodejs\node.exe'
    )) {
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    $nvmRoot = Join-Path $env:USERPROFILE '.nvm\versions\node'
    if (Test-Path $nvmRoot) {
        $candidate = Get-ChildItem -Path $nvmRoot -Recurse -Filter 'node.exe' -File -ErrorAction SilentlyContinue |
            Sort-Object FullName |
            Select-Object -Last 1
        if ($candidate) {
            return $candidate.FullName
        }
    }

    return $null
}

function Write-NodePathFile {
    param([string]$NodeBin)

    if (-not $NodeBin) {
        Write-Host 'warning: node not found during sync; Codex hooks will still depend on runtime PATH'
        return
    }

    Ensure-Dir $CodexHome
    $current = if (Test-Path $NodePathDest) { Get-Content $NodePathDest -Raw -ErrorAction SilentlyContinue } else { $null }
    if ($current) { $current = $current.Trim() }
    if ($current -eq $NodeBin) {
        Write-Host "node path unchanged: $NodePathDest"
        return
    }

    Invoke-Run "write node path $NodeBin -> $NodePathDest" {
        Set-Content -Path $NodePathDest -Value $NodeBin -Encoding UTF8
    }
    Write-Host "node path: $NodeBin"
}

function Invoke-NodeScript {
    param([string]$Script, [string]$ActionName, [string]$Target)

    if (-not (Test-Path $Script)) {
        Write-Host "skip $ActionName ($Script not found)"
        return
    }

    if (-not $script:NodeBin) {
        Write-Host "skip $ActionName (node not found)"
        return
    }

    if ($DryRun) {
        & $script:NodeBin $Script --dry-run $Target
    } else {
        & $script:NodeBin $Script $Target
    }
}

function Resolve-NormalizedPath {
    param([string]$Path)
    try {
        return (Resolve-Path -LiteralPath $Path).Path
    } catch {
        return $null
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

function Remove-ManagedFile {
    param([string]$Target)
    if (-not (Test-Path $Target)) { return }
    Invoke-Run "rm $Target" { Remove-Item $Target -Force }
    Write-Host "removed file: $Target"
}

function Install-One {
    param([string]$Src, [string]$Target)

    if (Test-Path $Target) {
        $resolvedSrc = Resolve-NormalizedPath $Src
        $resolvedTarget = Resolve-NormalizedPath $Target
        if ((Test-Symlink $Target) -and $resolvedSrc -and $resolvedTarget -and $resolvedSrc -eq $resolvedTarget) {
            Write-Host "skip (already linked): $Target"
        } else {
            Write-Host "skip (name exists, leaving alone): $Target"
        }
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
    $script:NodeBin = Resolve-NodeBin
    foreach ($name in $Skills)     { Uninstall-One (Join-Path $SkillsDest $name) }
    foreach ($name in $Agents)     { Uninstall-One (Join-Path $AgentsDest $name) }
    foreach ($name in $HookFiles)  { Uninstall-One (Join-Path $HooksDest $name) }
    foreach ($name in $AudioFiles) { Uninstall-One (Join-Path $AudioDest $name) }
    Invoke-NodeScript $ConfigMergeScript 'Codex config cleanup' "--remove:$ConfigDest"
    Invoke-NodeScript $HooksMergeScript 'Codex hooks cleanup' "--remove:$HooksJsonDest"
    Remove-ManagedFile $NodePathDest
    exit 0
}

$script:NodeBin = Resolve-NodeBin
Write-NodePathFile $script:NodeBin

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

# Hooks
if ($HookFiles.Count -gt 0) {
    Ensure-Dir $HooksDest
    Write-Host "hooks: $HooksSrc -> $HooksDest"
    foreach ($name in $HookFiles) {
        Install-One (Join-Path $HooksSrc $name) (Join-Path $HooksDest $name)
    }
    Write-Host ''
}

# Audio
if ($AudioFiles.Count -gt 0) {
    Ensure-Dir $AudioDest
    Write-Host "audio: $AudioSrc -> $AudioDest"
    foreach ($name in $AudioFiles) {
        Install-One (Join-Path $AudioSrc $name) (Join-Path $AudioDest $name)
    }
    Write-Host ''
}

# Codex config merge
$ConfigMerged = 0
if (Test-Path $ConfigMergeScript) {
    Ensure-Dir $CodexHome
    Write-Host "config: merge ai-harness settings into $ConfigDest"
    Invoke-NodeScript $ConfigMergeScript 'Codex config merge' $ConfigDest
    $ConfigMerged = 1
    Write-Host ''
}

# Codex hooks.json merge
$HooksMerged = 0
if (Test-Path $HooksMergeScript) {
    Ensure-Dir $CodexHome
    Write-Host "hooks.json: merge ai-harness hooks into $HooksJsonDest"
    Invoke-NodeScript $HooksMergeScript 'Codex hooks merge' $HooksJsonDest
    $HooksMerged = 1
    Write-Host ''
}

$total = $Skills.Count + $Agents.Count + $HookFiles.Count + $AudioFiles.Count + $ConfigMerged + $HooksMerged
Write-Host "done. processed $total item(s):"
foreach ($name in $Skills)     { Write-Host "  skill: $name" }
foreach ($name in $Agents)     { Write-Host "  agent: $name" }
foreach ($name in $HookFiles)  { Write-Host "  hook: $name" }
foreach ($name in $AudioFiles) { Write-Host "  audio: $name" }
if ($ConfigMerged -eq 1) {
    Write-Host "  config: $ConfigDest"
}
if ($HooksMerged -eq 1) {
    Write-Host "  hooks.json: $HooksJsonDest"
}
