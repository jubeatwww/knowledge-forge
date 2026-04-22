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
$ScriptDir  = $PSScriptRoot
$SkillsSrc      = Join-Path $ScriptDir 'skills'
$AgentsSrc      = Join-Path $ScriptDir 'agents'
$CommandsSrc    = Join-Path $ScriptDir 'commands'
$HooksSrc       = Join-Path $ScriptDir 'hooks'
$AudioSrc       = Resolve-Path -LiteralPath (Join-Path $ScriptDir '..\audio') -ErrorAction SilentlyContinue
if (-not $AudioSrc) { $AudioSrc = Join-Path $ScriptDir '..\audio' } else { $AudioSrc = $AudioSrc.Path }
$StatuslineSrc  = Join-Path (Join-Path $ScriptDir 'statusline') 'statusline-command.sh'
$SettingsSrc    = Join-Path $ScriptDir 'settings.json'
$ClaudeHome     = Join-Path $env:USERPROFILE '.claude'
$SkillsDest     = Join-Path $ClaudeHome 'skills'
$AgentsDest     = Join-Path $ClaudeHome 'agents'
$CommandsDest   = Join-Path $ClaudeHome 'commands'
$HooksDest      = Join-Path $ClaudeHome 'hooks'
$AudioDest      = Join-Path $ClaudeHome 'audio'
$StatuslineDest = Join-Path $ClaudeHome 'statusline-command.sh'
$SettingsDest   = Join-Path $ClaudeHome 'settings.json'
$NodePathDest   = Join-Path $ClaudeHome 'ai-harness-node-path.txt'

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

if ($Skills.Count -eq 0 -and $Agents.Count -eq 0 -and $Commands.Count -eq 0 `
    -and $HookFiles.Count -eq 0 -and $AudioFiles.Count -eq 0 `
    -and -not (Test-Path $StatuslineSrc) -and -not (Test-Path $SettingsSrc)) {
    Write-Error 'nothing to install — no skills, agents, commands, hooks, audio, statusline, or settings found'
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

function Resolve-NormalizedPath {
    param([string]$Path)
    try {
        return (Resolve-Path -LiteralPath $Path).Path
    } catch {
        return $null
    }
}

function Write-NodePathFile {
    param([string]$NodeBin)

    if (-not $NodeBin) {
        Write-Host 'warning: node not found during sync; hook commands will still depend on runtime PATH'
        return
    }

    Ensure-Dir $ClaudeHome
    $current = if (Test-Path $NodePathDest) { Get-Content $NodePathDest -Raw -ErrorAction SilentlyContinue } else { $null }
    if ($current) {
        $current = $current.Trim()
    }
    if ($current -eq $NodeBin) {
        Write-Host "node path unchanged: $NodePathDest"
        return
    }

    Invoke-Run "write node path $NodeBin -> $NodePathDest" {
        Set-Content -Path $NodePathDest -Value $NodeBin -Encoding UTF8
    }
    Write-Host "node path: $NodeBin"
}

function Get-RenderedSettingsObject {
    $proj = Get-Content $SettingsSrc -Raw | ConvertFrom-Json
    if (-not $script:NodeBin) {
        return $proj
    }

    foreach ($hookGroup in $proj.hooks.PSObject.Properties) {
        foreach ($matcher in $hookGroup.Value) {
            foreach ($hook in $matcher.hooks) {
                if ($hook.type -ne 'command') { continue }
                if ($hook.command -notmatch ' (?<event>[^ ]+)$') { continue }
                $event = $Matches['event']
                $hook.command = "`"$script:NodeBin`" `$HOME/.claude/hooks/play-sound.mjs $event"
            }
        }
    }

    return $proj
}

function Merge-Settings {
    if (-not (Test-Path $SettingsSrc)) { return }
    Ensure-Dir $ClaudeHome
    if (-not (Test-Path $SettingsDest)) {
        Invoke-Run "create $SettingsDest from rendered settings template" {
            $proj = Get-RenderedSettingsObject
            $proj | ConvertTo-Json -Depth 20 | Set-Content $SettingsDest -Encoding UTF8
        }
        Write-Host "created: $SettingsDest"
        return
    }
    Invoke-Run "merge hooks from $SettingsSrc into $SettingsDest" {
        $proj = Get-RenderedSettingsObject
        $user = Get-Content $SettingsDest -Raw | ConvertFrom-Json
        if ($user.PSObject.Properties.Name -contains 'hooks') {
            $user.hooks = $proj.hooks
        } else {
            $user | Add-Member -NotePropertyName 'hooks' -NotePropertyValue $proj.hooks
        }
        $user | ConvertTo-Json -Depth 20 | Set-Content $SettingsDest -Encoding UTF8
    }
    Write-Host "merged hooks block into: $SettingsDest"
}

function Uninstall-Settings {
    if (-not (Test-Path $SettingsDest)) { return }
    Invoke-Run "remove hooks key from $SettingsDest" {
        $user = Get-Content $SettingsDest -Raw | ConvertFrom-Json
        if ($user.PSObject.Properties.Name -contains 'hooks') {
            $user.PSObject.Properties.Remove('hooks')
            $user | ConvertTo-Json -Depth 20 | Set-Content $SettingsDest -Encoding UTF8
            Write-Host "removed hooks block from: $SettingsDest"
        }
    }
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
    foreach ($name in $Skills)   { Uninstall-One (Join-Path $SkillsDest $name) }
    foreach ($name in $Agents)   { Uninstall-One (Join-Path $AgentsDest $name) }
    foreach ($name in $Commands)   { Uninstall-One (Join-Path $CommandsDest $name) }
    foreach ($name in $HookFiles)  { Uninstall-One (Join-Path $HooksDest $name) }
    foreach ($name in $AudioFiles) { Uninstall-One (Join-Path $AudioDest $name) }
    Uninstall-One $StatuslineDest
    Uninstall-Settings
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

# Slash commands
if ($Commands.Count -gt 0) {
    Ensure-Dir $CommandsDest
    Write-Host "commands: $CommandsSrc -> $CommandsDest"
    foreach ($name in $Commands) {
        Install-One (Join-Path $CommandsSrc $name) (Join-Path $CommandsDest $name)
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

# Statusline
$StatuslineInstalled = 0
if (Test-Path $StatuslineSrc) {
    Ensure-Dir $ClaudeHome
    Write-Host "statusline: $StatuslineSrc -> $StatuslineDest"
    Install-One $StatuslineSrc $StatuslineDest
    $StatuslineInstalled = 1
    Write-Host ''
}

# settings.json hooks merge (always merge, regardless of -Copy / symlink mode).
$SettingsInstalled = 0
if (Test-Path $SettingsSrc) {
    Write-Host "settings: merge hooks from $SettingsSrc into $SettingsDest"
    Merge-Settings
    $SettingsInstalled = 1
    Write-Host ''
}

$total = $Skills.Count + $Agents.Count + $Commands.Count + $HookFiles.Count + $AudioFiles.Count + $StatuslineInstalled + $SettingsInstalled
Write-Host "done. processed $total item(s):"
foreach ($name in $Skills)     { Write-Host "  skill:   $name" }
foreach ($name in $Agents)     { Write-Host "  agent:   $name" }
foreach ($name in $Commands)   { Write-Host "  command: $name" }
foreach ($name in $HookFiles)  { Write-Host "  hook:    $name" }
foreach ($name in $AudioFiles) { Write-Host "  audio:   $name" }
if ($StatuslineInstalled -eq 1) {
    Write-Host "  statusline: $StatuslineDest"
}
if ($SettingsInstalled -eq 1) {
    Write-Host "  settings:   $SettingsDest (hooks merged)"
}
