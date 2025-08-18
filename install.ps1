<<<<<<< Updated upstream
=======
<#
 Copyright (C) 2025 Jonathan Miller || Moko Consulting <jmiller@mokoconsulting.tech>
 This file is part of a Moko Consulting project.
 SPDX-License-Identifier: GPL-3.0-or-later
 This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
#>

<# FILE INFORMATION
 INGROUP:  Copy-PortablePath
 FILE:     install.ps1
 VERSION:  1.0
 BRIEF:    Self-contained installer for Copy-PortablePath with PATH management, manifest, and Explorer context menu (with folder fix).
 PATH:     .\install.ps1
 NOTE:     Designed for Windows PowerShell 5.1+ and PowerShell 7+; supports User or System scope installs with idempotent re-runs.
#>

<#
.SYNOPSIS
  Installs Copy-PortablePath and optionally adds its install directory to PATH.

.DESCRIPTION
  This installer copies the tool script(s) to a chosen install directory, writes an installation manifest (JSON), and updates PATH for the selected scope (User or System). If no external payload is provided via -Source and no sibling Copy-PortablePath.ps1 is found, it installs an embedded minimal stub tool so the installer is fully self-contained.

.PARAMETER Source
  Path or HTTPS URL to the Copy-PortablePath payload. If a directory is provided, all *.ps1 files inside are installed. If omitted and no sibling tool is present, an embedded minimal Copy-PortablePath.ps1 stub is installed.

.PARAMETER InstallDir
  Target install directory. Defaults to "$env:LOCALAPPDATA\Copy-PortablePath" for -Scope User and "$env:ProgramFiles\Copy-PortablePath" for -Scope System.

.PARAMETER Scope
  Installation scope: 'User' updates the current user's PATH; 'System' updates the machine PATH (requires elevation). Values: User, System.

.PARAMETER NoPath
  Skip PATH modification. Files are installed and manifest is written, but PATH is not changed.

.PARAMETER Uninstall
  Remove installed files, remove PATH entry, and delete manifest for the selected Scope.

.PARAMETER Force
  Overwrite existing files and re-add PATH entry even if already present.

.PARAMETER Reinstall
  Perform a clean reinstall: remove any existing installation (files, manifest, PATH entry) before installing. Implies legacy cleanup (removes any old `Copy-PortablePath\bin` PATH entries).

.PARAMETER Silent
  Run without prompts: default to -Scope User and -Reinstall unless overridden. Suppresses the scope and existing-install menus.

.PARAMETER AddProfileAlias
  Add a 'cpp' convenience function to your PowerShell profile (CurrentUserAllHosts) that invokes the installed shim.

.PARAMETER Sign
  Sign installed PowerShell scripts using a code-signing certificate.

.PARAMETER CertThumbprint
  Thumbprint of a code-signing certificate in the CurrentUser/LocalMachine 'My' store to use when -Sign is present.

.PARAMETER CertPath
  Path to a .pfx file (with private key) to use for signing.

.PARAMETER CertPassword
  Password for the .pfx (secure string). If omitted, you'll be prompted when loading the PFX.

.PARAMETER TimestampServer
  RFC 3161 timestamp server URL. Default: http://timestamp.digicert.com

.PARAMETER PostAction
  What to do after install/uninstall: None, RestartExplorer, KillExplorer, StartExplorer, RestartSystem.

.PARAMETER RegisterContextMenu
  Add Explorer right-click menu entries under All files/folders, Directory (folder items), Drive, and Folder background. Uses HKCU; on Windows 11 they appear under "Show more options".

.PARAMETER UnregisterContextMenu
  Remove previously added right-click menu entries.

.PARAMETER ContextIcon
  Optional icon resource for the Explorer verb. Use Windows resource paths like `%SystemRoot%\System32\shell32.dll,-142` (clipboard). If omitted, defaults to that clipboard icon.

.PARAMETER RepoUrl
  Repository URL written into the manifest. Defaults to https://github.com/mokoconsulting-tech/Copy-PortablePath

.PARAMETER ManifestPath
  Custom path to manifest JSON. Defaults to '<InstallDir>\\install-manifest.json'.

.PARAMETER Version
  Version string to record in manifest and shim banner. If not provided, the installer reads a 'VERSION' file next to install.ps1; if none is found, defaults to '1.0'.
#>

[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
  [Parameter(Position=0)]
  [string]$Source,

  [string]$InstallDir,

  [ValidateSet('User','System')]
  [string]$Scope = 'User',

  [switch]$NoPath,
  [switch]$Uninstall,
  [switch]$Force,

  [switch]$Reinstall,
  [switch]$Silent,
  [switch]$AddProfileAlias,
  [switch]$Sign,
  [string]$CertThumbprint,
  [string]$CertPath,
  [SecureString]$CertPassword,
  [string]$TimestampServer = 'http://timestamp.digicert.com',
  [ValidateSet('None','RestartExplorer','KillExplorer','StartExplorer','RestartSystem')]
  [string]$PostAction = 'None',
  [switch]$RegisterContextMenu,
  [switch]$UnregisterContextMenu,
  [string]$ContextIcon,
  [string]$RepoUrl = 'https://github.com/mokoconsulting-tech/Copy-PortablePath',
  [string]$ManifestPath,
  [string]$Version = '1.0'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region Version resolution
$__scriptRootEarly = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Path $MyInvocation.MyCommand.Path -Parent }
if (-not $__scriptRootEarly) { $__scriptRootEarly = (Get-Location).Path }
if (-not $PSBoundParameters.ContainsKey('Version') -or [string]::IsNullOrWhiteSpace($Version)) {
  $verFile = Join-Path $__scriptRootEarly 'VERSION'
  if (Test-Path $verFile) { $Version = (Get-Content -LiteralPath $verFile -Raw).Trim() } else { $Version = '1.0' }
}
#endregion

#region Logging
$ScriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Path $MyInvocation.MyCommand.Path -Parent }
if (-not $ScriptRoot) { $ScriptRoot = (Get-Location).Path }
$LogDir = Join-Path $ScriptRoot 'logs'
try { if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null } } catch {}
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$action = if ($Uninstall) { 'uninstall' } else { 'install' }
$LogPath = Join-Path $LogDir ("copy-portablepath-" + $action + "-$Scope-" + $stamp + ".log")
$TranscriptStarted = $false
try { Start-Transcript -Path $LogPath -IncludeInvocationHeader -Force -ErrorAction Stop | Out-Null; $TranscriptStarted = $true; Write-Verbose "Transcript started: $LogPath" } catch { Write-Warning "Unable to start transcript logging: $($_.Exception.Message)" }
#endregion

#region Interactive: scope
if ($Silent -and -not $PSBoundParameters.ContainsKey('Scope')) { $Scope = 'User' }
if (-not $PSBoundParameters.ContainsKey('Scope') -and -not $Silent) {
  $choices = @(
    (New-Object System.Management.Automation.Host.ChoiceDescription '&User','Install for current user (no admin).'),
    (New-Object System.Management.Automation.Host.ChoiceDescription '&System','Install for all users (requires admin).')
  )
  $sel = $Host.UI.PromptForChoice('Install scope','Choose installation scope:', $choices, 0)
  $Scope = if ($sel -eq 1) { 'System' } else { 'User' }
}
if ($Scope -eq 'System') {
  try {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    if (-not $p.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) { Write-Warning 'System scope requires administrative privileges; continuing with User scope.'; $Scope = 'User' }
  } catch { Write-Warning 'Unable to determine admin status; using User scope.'; $Scope = 'User' }
}
#endregion

#region Utility: admin/env broadcast
function Test-IsAdmin {
  try { $p = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent()); return $p.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator) } catch { return $false }
}
if (-not ([System.Management.Automation.PSTypeName]'EnvBroadcast').Type) {
Add-Type -Language CSharp -TypeDefinition @"
using System; using System.Runtime.InteropServices;
public static class EnvBroadcast {
  public const int HWND_BROADCAST = 0xffff; public const int WM_SETTINGCHANGE = 0x001A; public const int SMTO_ABORTIFHUNG = 0x0002;
  [DllImport("user32.dll", SetLastError=true, CharSet=CharSet.Auto)]
  public static extern IntPtr SendMessageTimeout(IntPtr hWnd, int Msg, IntPtr wParam, string lParam, int fuFlags, int uTimeout, out IntPtr lpdwResult);
  public static void Broadcast() { IntPtr r; SendMessageTimeout((IntPtr)HWND_BROADCAST, WM_SETTINGCHANGE, IntPtr.Zero, "Environment", SMTO_ABORTIFHUNG, 5000, out r); }
}
"@
}
#endregion

#region PATH helpers
function Get-CurrentPathValue { param([ValidateSet('User','System')][string]$Scope) if ($Scope -eq 'System') { [Environment]::GetEnvironmentVariable('Path','Machine') } else { [Environment]::GetEnvironmentVariable('Path','User') } }
function Set-PathValue { param([ValidateSet('User','System')][string]$Scope,[string]$NewValue)
  if ($Scope -eq 'System') { [Environment]::SetEnvironmentVariable('Path',$NewValue,'Machine') } else { [Environment]::SetEnvironmentVariable('Path',$NewValue,'User') }
  $m=[Environment]::GetEnvironmentVariable('Path','Machine'); $u=[Environment]::GetEnvironmentVariable('Path','User'); if ([string]::IsNullOrEmpty($m)){$env:Path=$u}elseif([string]::IsNullOrEmpty($u)){$env:Path=$m}else{$env:Path="$m;$u"}; [EnvBroadcast]::Broadcast()
}
function Add-ToPath { [CmdletBinding()] param([string]$Dir,[ValidateSet('User','System')][string]$Scope,[switch]$Force)
  $n=$Dir.TrimEnd('\\/'); $cur=Get-CurrentPathValue -Scope $Scope; $parts=@(); if($cur){$parts=$cur.Split(';')|?{$_}}; if(-not $Force){foreach($p in $parts){ if($p.TrimEnd('\\/') -ieq $n){ Write-Verbose "PATH already contains $n"; return $cur } }}; $new=($parts+$n)-join ';'; Set-PathValue -Scope $Scope -NewValue $new; return $new }
function Remove-FromPath { [CmdletBinding()] param([string]$Dir,[ValidateSet('User','System')][string]$Scope)
  $n=$Dir.TrimEnd('\\/'); $cur=Get-CurrentPathValue -Scope $Scope; if(-not $cur){return $null}; $parts=$cur.Split(';')|?{$_}; $filtered=@(); foreach($p in $parts){ if($p.TrimEnd('\\/') -ine $n){ $filtered+=$p }}; $new=($filtered -join ';'); Set-PathValue -Scope $Scope -NewValue $new; return $new }
#endregion

#region Legacy cleanup
function Remove-LegacyEntries { [CmdletBinding()] param([ValidateSet('User','System')][string]$Scope)
  $base = if ($Scope -eq 'System') { $env:ProgramFiles } else { $env:LOCALAPPDATA }
  $legacy = Join-Path $base 'Copy-PortablePath\bin'
  if (Test-Path $legacy) { Write-Verbose "Removing legacy directory: $legacy"; Remove-Item -LiteralPath $legacy -Recurse -Force -ErrorAction SilentlyContinue }
  try { Remove-FromPath -Dir $legacy -Scope $Scope | Out-Null } catch {}
}
#endregion

#region Manifest
function Get-SHA256 { param([string]$Path) (Get-FileHash -Path $Path -Algorithm SHA256).Hash }
function Write-Manifest { [CmdletBinding()] param([string]$ManifestPath,[string]$InstallDir,[string]$RepoUrl,[string]$Version,[string[]]$InstalledFiles)
  $m=[ordered]@{packageName='Copy-PortablePath';version=$Version;installDate=(Get-Date).ToString('o');scope=$Scope;installDir=$InstallDir;repoUrl=$RepoUrl;files=@()}; foreach($f in $InstalledFiles){$m.files+=@{path=$f;sha256=(Get-SHA256 $f)}}; $json=$m|ConvertTo-Json -Depth 6; $dir=Split-Path $ManifestPath -Parent; if(-not(Test-Path $dir)){New-Item -ItemType Directory -Path $dir -Force|Out-Null}; $json | Out-File -FilePath $ManifestPath -Encoding UTF8 -Force; return $ManifestPath }
#endregion

#region Post actions
function Stop-Explorer { Get-Process -Name explorer -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue }
function Start-Explorer { Start-Process explorer.exe | Out-Null }
function Restart-Explorer { Stop-Explorer; Start-Sleep -Milliseconds 300; Start-Explorer }
function Invoke-PostAction { param([ValidateSet('None','RestartExplorer','KillExplorer','StartExplorer','RestartSystem')][string]$Action)
  switch($Action){
    'RestartExplorer'{Restart-Explorer;Write-Host 'Explorer restarted.' -ForegroundColor DarkGreen}
    'KillExplorer'{Stop-Explorer;Write-Host 'Explorer terminated. Launch explorer.exe to restore the shell.' -ForegroundColor Yellow}
    'StartExplorer'{Start-Explorer;Write-Host 'Explorer started.' -ForegroundColor DarkGreen}
    'RestartSystem'{try{shutdown.exe /r /t 0;return}catch{};try{Restart-Computer -Force}catch{Write-Warning "Failed to request restart: $($_.Exception.Message)"}}
    Default{}
  }
}
#endregion

#region Context menu (with folder fix)
function Register-ContextMenu {
  [CmdletBinding()] param([Parameter(Mandatory=$true)][string]$InstallDir,[string]$ContextIcon)
  $shim = Join-Path $InstallDir 'copy-portablepath.cmd'
  if (-not (Test-Path $shim)) { Write-Warning "Shim not found at $shim; skipping context menu registration."; return }
  $base = 'HKCU:\Software\Classes'
  $icon = if ($PSBoundParameters.ContainsKey('ContextIcon') -and -not [string]::IsNullOrWhiteSpace($ContextIcon)) { $ContextIcon } else { '%SystemRoot%\System32\imageres.dll,-5382' }
  $items = @(
    @{ Key = (Join-Path $base 'AllFilesystemObjects\shell\Copy-PortablePath'); Verb='Copy Portable Path'; Command = ('"{0}" "%1" -Clip' -f $shim) },
    @{ Key = (Join-Path $base 'Directory\shell\Copy-PortablePath');          Verb='Copy Portable Path'; Command = ('"{0}" "%1" -Clip' -f $shim) },
    @{ Key = (Join-Path $base 'Drive\shell\Copy-PortablePath');               Verb='Copy Portable Path'; Command = ('"{0}" "%1" -Clip' -f $shim) },
    @{ Key = (Join-Path $base 'Directory\Background\shell\Copy-PortablePath'); Verb='Copy Portable Path'; Command = ('"{0}" "%V" -Clip' -f $shim) }
  )
  foreach ($it in $items) {
    New-Item -Path $it.Key -Force | Out-Null
    New-ItemProperty -Path $it.Key -Name 'MUIVerb' -Value $it.Verb -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $it.Key -Name 'Icon'   -Value $icon -PropertyType ExpandString -Force | Out-Null
    foreach ($flag in 'Extended','LegacyDisable') { try { Remove-ItemProperty -Path $it.Key -Name $flag -ErrorAction SilentlyContinue } catch {} }
    $cmdKey = Join-Path $it.Key 'command'
    New-Item -Path $cmdKey -Force | Out-Null
    try { Set-ItemProperty -Path $cmdKey -Name '(default)' -Value $it.Command -ErrorAction Stop }
    catch { New-ItemProperty -Path $cmdKey -Name '(default)' -Value $it.Command -PropertyType String -Force | Out-Null }
  }
  Write-Host "Registered Explorer context menu entries (Windows 11: see 'Show more options')." -ForegroundColor DarkGreen
}
function Unregister-ContextMenu { [CmdletBinding()] param()
  $keys = @(
    'HKCU:\Software\Classes\AllFilesystemObjects\shell\Copy-PortablePath',
    'HKCU:\Software\Classes\Directory\shell\Copy-PortablePath',
    'HKCU:\Software\Classes\Drive\shell\Copy-PortablePath',
    'HKCU:\Software\Classes\Directory\Background\shell\Copy-PortablePath'
  )
  foreach ($k in $keys) { if (Test-Path $k) { Remove-Item -Path $k -Recurse -Force -ErrorAction SilentlyContinue } }
  Write-Host 'Removed Explorer context menu entries.' -ForegroundColor Yellow
}
#endregion

#region Defaults
if (-not $InstallDir) { $InstallDir = if ($Scope -eq 'System') { Join-Path $env:ProgramFiles 'Copy-PortablePath' } else { Join-Path $env:LOCALAPPDATA 'Copy-PortablePath' } }
if (-not $ManifestPath) { $ManifestPath = Join-Path $InstallDir 'install-manifest.json' }
#endregion

#region Existing installation flow
$__willPromptExisting = -not $Silent
if ($Silent) { $Reinstall = $true }
if ($PSBoundParameters.ContainsKey('Reinstall') -or $Uninstall -or $Force) { $__willPromptExisting = $false }
if ($__willPromptExisting -and (Test-Path $InstallDir)) {
  $msg = "An installation already exists at `"$InstallDir`". What would you like to do?"
  $choices = @(
    (New-Object System.Management.Automation.Host.ChoiceDescription '&Reinstall','Uninstall existing then install fresh (recommended).'),
    (New-Object System.Management.Automation.Host.ChoiceDescription '&Uninstall','Remove existing installation and exit.'),
    (New-Object System.Management.Automation.Host.ChoiceDescription '&Leave','Leave existing installation unchanged and exit.')
  )
  $sel = $Host.UI.PromptForChoice('Existing installation detected', $msg, $choices, 0)
  switch ($sel) {
    0 { $Reinstall = $true }
    1 { $Uninstall = $true }
    2 { Write-Host "Leaving existing installation at $InstallDir unchanged." -ForegroundColor Yellow; Invoke-PostAction -Action $PostAction; if ($TranscriptStarted) { try { Stop-Transcript | Out-Null } catch {} }; if ($LogPath) { Write-Host "Log written: $LogPath" -ForegroundColor DarkGreen }; return }
  }
}
#endregion

#region Interactive: post action
if (-not $Silent -and -not $PSBoundParameters.ContainsKey('PostAction')) {
  $choices = @(
    (New-Object System.Management.Automation.Host.ChoiceDescription 'Restart &Explorer','Kill and restart explorer.exe.'),
    (New-Object System.Management.Automation.Host.ChoiceDescription '&Kill Explorer','Terminate explorer.exe and leave it closed.'),
    (New-Object System.Management.Automation.Host.ChoiceDescription 'Start E&xplorer','Launch explorer.exe if not running.'),
    (New-Object System.Management.Automation.Host.ChoiceDescription 'Re&boot System','Restart Windows now.'),
    (New-Object System.Management.Automation.Host.ChoiceDescription '&Do Nothing','No post-action.')
  )
  $sel = $Host.UI.PromptForChoice('Post-install action','Choose what to do after install/uninstall:', $choices, 4)
  $PostAction = @('RestartExplorer','KillExplorer','StartExplorer','RestartSystem','None')[$sel]
}
#endregion

#region Uninstall
if ($Uninstall) {
  if ($PSCmdlet.ShouldProcess("Uninstall Copy-PortablePath from $InstallDir (scope=$Scope)", 'Remove files and PATH entry')) {
    if (Test-Path $InstallDir) { Write-Verbose "Removing directory: $InstallDir"; Remove-Item -LiteralPath $InstallDir -Recurse -Force -ErrorAction SilentlyContinue } else { Write-Verbose "Install directory not found: $InstallDir" }
    if (-not $NoPath) { Write-Verbose "Removing PATH entry for: $InstallDir"; Remove-FromPath -Dir $InstallDir -Scope $Scope | Out-Null }
    if (Test-Path $ManifestPath) { Write-Verbose "Removing manifest: $ManifestPath"; Remove-Item -LiteralPath $ManifestPath -Force -ErrorAction SilentlyContinue }
    try { Unregister-ContextMenu } catch {}
  }
  Write-Host "Copy-PortablePath uninstalled from scope=$Scope." -ForegroundColor Green
  Invoke-PostAction -Action $PostAction
  if ($TranscriptStarted) { try { Stop-Transcript | Out-Null } catch {} }
  if ($LogPath) { Write-Host "Log written: $LogPath" -ForegroundColor DarkGreen }
  return
}
#endregion

#region Pre-install cleanup
try { Remove-LegacyEntries -Scope $Scope } catch {}
$doReinstall = $Reinstall -or $Force -or (Test-Path $InstallDir)
if ($doReinstall) {
  if ($PSCmdlet.ShouldProcess("Reinstall Copy-PortablePath", "Clean uninstall then install")) {
    if (Test-Path $InstallDir) { Write-Verbose "Removing prior install dir: $InstallDir"; Remove-Item -LiteralPath $InstallDir -Recurse -Force -ErrorAction SilentlyContinue }
    if (-not $NoPath) { Write-Verbose "Removing PATH entry for prior install"; Remove-FromPath -Dir $InstallDir -Scope $Scope | Out-Null }
    if (Test-Path $ManifestPath) { Write-Verbose "Removing prior manifest: $ManifestPath"; Remove-Item -LiteralPath $ManifestPath -Force -ErrorAction SilentlyContinue }
  }
}
#endregion

#region Resolve payload (self-contained)
function Resolve-Payload { param([string]$Source)
  if ([string]::IsNullOrWhiteSpace($Source)) { $local = Join-Path -Path (Get-Location) -ChildPath 'Copy-PortablePath.ps1'; if (Test-Path $local) { return (Resolve-Path $local).Path }; return (Get-Location).Path }
  if ($Source -match '^(http|https)://') { $tmp = Join-Path $env:TEMP ("cpp_" + [IO.Path]::GetRandomFileName() + [IO.Path]::GetExtension($Source)); Write-Verbose "Downloading payload: $Source -> $tmp"; Invoke-WebRequest -Uri $Source -OutFile $tmp; return $tmp }
  return (Resolve-Path $Source).Path }
function Get-PayloadFiles { param([string]$Resolved) if (Test-Path $Resolved -PathType Leaf) { ,$Resolved } elseif (Test-Path $Resolved -PathType Container) { Get-ChildItem -LiteralPath $Resolved -Filter '*.ps1' -File | Select-Object -ExpandProperty FullName } else { throw "Payload not found: $Resolved" } }

$ResolvedSource = Resolve-Payload -Source $Source
$PayloadFiles = @(); if ($ResolvedSource) { $PayloadFiles = Get-PayloadFiles -Resolved $ResolvedSource }
$SelfPath = $MyInvocation.MyCommand.Path; $hasRealPayload = $false; foreach ($f in $PayloadFiles) { if ((Split-Path -Leaf $f) -ne (Split-Path -Leaf $SelfPath)) { $hasRealPayload = $true; break } }
if (-not $hasRealPayload) {
  Write-Verbose "No external payload found. Using embedded Copy-PortablePath.ps1 payload."
  $tempPayload = Join-Path $env:TEMP "Copy-PortablePath.ps1"
  $EmbeddedPayload = @'
[CmdletBinding()] param(
  [Parameter(Position=0,Mandatory=$false,HelpMessage='File or folder to convert to a portable path')]
  [string]$Path = (Get-Location).Path,
  [switch]$Clip,
  [Alias('h','?')][switch]$Help, [switch]$HistoryShow, [switch]$HistoryClear, [int]$Tail = 100)
if ($Help) { Write-Host "Copy-PortablePath — stub" -ForegroundColor Cyan; Write-Host "Usage: Copy-PortablePath.ps1 [-Path <dirOrFile>] [-Clip]" -ForegroundColor Gray; exit 0 }
if ($HistoryClear) { try { $toolRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Path $MyInvocation.MyCommand.Path -Parent }; if (-not $toolRoot) { $toolRoot = (Get-Location).Path }; $histDir = Join-Path $toolRoot 'logs'; $histFile = Join-Path $histDir ("history-" + (Get-Date -Format 'yyyyMMdd') + ".log"); if (Test-Path $histFile) { Remove-Item -LiteralPath $histFile -Force }; Write-Host "Cleared today's history log." -ForegroundColor Green } catch { Write-Warning $_.Exception.Message }; exit 0 }
if ($HistoryShow) { try { $toolRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Path $MyInvocation.MyCommand.Path -Parent }; if (-not $toolRoot) { $toolRoot = (Get-Location).Path }; $histDir = Join-Path $toolRoot 'logs'; $histFile = Join-Path $histDir ("history-" + (Get-Date -Format 'yyyyMMdd') + ".log"); if (Test-Path $histFile) { $lines = Get-Content -LiteralPath $histFile -Encoding UTF8; if ($Tail -gt 0 -and $lines.Count -gt $Tail) { $lines[-$Tail..-1] } else { $lines } } else { Write-Host "No history for today." -ForegroundColor Yellow } } catch { Write-Warning $_.Exception.Message }; exit 0 }
$resolved = $null; try { $resolved = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).ProviderPath } catch { Write-Error "Path not found: $Path"; exit 1 }
$out = $resolved -replace '\\','/'; Write-Output $out
try { $toolRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Path $MyInvocation.MyCommand.Path -Parent }; if (-not $toolRoot) { $toolRoot = (Get-Location).Path }; $histDir = Join-Path $toolRoot 'logs'; if (-not (Test-Path $histDir)) { New-Item -ItemType Directory -Path $histDir -Force | Out-Null }; $histFile = Join-Path $histDir ("history-" + (Get-Date -Format 'yyyyMMdd') + ".log"); $entry = [ordered]@{ ts=(Get-Date).ToString('o'); user=$env:USERNAME; host=$env:COMPUTERNAME; pwsh=$PSVersionTable.PSVersion.ToString(); pathArg=$Path; resolved=$out; clip=[bool]$Clip }; ($entry | ConvertTo-Json -Depth 5) | Add-Content -Path $histFile -Encoding UTF8 } catch {}
try { if ($Clip) { Set-Clipboard -Value $out -ErrorAction Stop } } catch { Write-Warning "Clipboard not available in this host." }
'@
  Set-Content -Path $tempPayload -Value $EmbeddedPayload -Encoding UTF8
  $PayloadFiles = ,$tempPayload
}
if (-not $PayloadFiles -or @($PayloadFiles).Count -eq 0) { throw "No payload files were found to install." }
Write-Verbose ("Payload files: " + ($PayloadFiles -join ', '))
#endregion

#region Install
if ($PSCmdlet.ShouldProcess("Install to $InstallDir", "Copy $(@($PayloadFiles).Count) file(s) and update PATH")) {
  if (-not (Test-Path $InstallDir)) { New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null }
  $installed=@(); foreach($src in $PayloadFiles){ $dst=Join-Path $InstallDir (Split-Path -Leaf $src); if((Test-Path $dst) -and -not $Force){ Write-Verbose "Exists (skip): $dst" } else { Copy-Item -LiteralPath $src -Destination $dst -Force; $installed+=$dst }}
  if (-not $NoPath) { Add-ToPath -Dir $InstallDir -Scope $Scope -Force:$Force | Out-Null }
  Write-Host "Installed Copy-PortablePath to: $InstallDir" -ForegroundColor Green
  try { Set-Content -Path (Join-Path $InstallDir 'VERSION') -Value $Version -Encoding ASCII -Force } catch { Write-Verbose "Unable to write VERSION file: $($_.Exception.Message)" }
  try { $shimPath = Join-Path $InstallDir 'copy-portablepath.cmd'; $shim = @"
@echo off
setlocal
REM Copy-PortablePath v$Version
REM Installed: %DATE% %TIME%
set PSH=pwsh
where %PSH% >nul 2>nul || set PSH=powershell
"%PSH%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0Copy-PortablePath.ps1" %*
"@; Set-Content -Path $shimPath -Value $shim -Encoding ASCII -Force; Write-Verbose "Shim created: $shimPath" } catch { Write-Warning "Failed to create shim: $($_.Exception.Message)" }
  if (-not $NoPath) { Write-Host "PATH updated for scope=$Scope." -ForegroundColor DarkGreen }
  if ($AddProfileAlias) { try { $profilePath=$PROFILE.CurrentUserAllHosts; $profileDir=Split-Path $profilePath -Parent; if(-not(Test-Path $profileDir)){New-Item -ItemType Directory -Path $profileDir -Force|Out-Null}; if(-not(Test-Path $profilePath)){New-Item -ItemType File -Path $profilePath -Force|Out-Null}; $cmdPath=Join-Path $InstallDir 'copy-portablepath.cmd'; $fn=@"
function cpp {
  param([Parameter(ValueFromRemainingArguments=`$true)][object[]] `$Args)
  & '$cmdPath' @Args
}
"@; $existing=Get-Content -LiteralPath $profilePath -Raw -ErrorAction SilentlyContinue; if($existing -notmatch 'function cpp'){ Add-Content -Path $profilePath -Value "`r`n$fn" -Encoding UTF8; Write-Host "Added 'cpp' function to $profilePath" -ForegroundColor DarkGreen } else { Write-Verbose "Profile already defines 'cpp'; skipped" } } catch { Write-Warning "Failed to add profile alias: $($_.Exception.Message)" } }
  try { if ($RegisterContextMenu) { Register-ContextMenu -InstallDir $InstallDir -ContextIcon $ContextIcon } elseif ($UnregisterContextMenu) { Unregister-ContextMenu } elseif (-not $Silent) { $cm=@((New-Object System.Management.Automation.Host.ChoiceDescription '&Yes','Add right-click menu entries to Explorer.'),(New-Object System.Management.Automation.Host.ChoiceDescription '&No','Skip integration.')); $ans=$Host.UI.PromptForChoice('Explorer integration','Add right-click "Copy Portable Path" to Explorer?', $cm, 0); if($ans -eq 0){ Register-ContextMenu -InstallDir $InstallDir -ContextIcon $ContextIcon } } } catch { Write-Warning ("Context menu registration error: {0}" -f $_.Exception.Message) }
  # Signing
  if ($Sign) {
    $cert=$null; try { if ($CertThumbprint) { $tp=($CertThumbprint -replace '\\s','').ToUpperInvariant(); foreach($store in 'Cert:\\CurrentUser\\My','Cert:\\LocalMachine\\My'){ $c=Get-ChildItem -Path $store -ErrorAction SilentlyContinue | Where-Object {$_.Thumbprint -eq $tp}; if($c){ $cert=($c|Select-Object -First 1); break } } } if(-not $cert -and $CertPath){ if(-not $CertPassword){ $CertPassword=Read-Host -AsSecureString "Password for PFX: $CertPath" }; $cert=New-Object System.Security.Cryptography.X509Certificates.X509Certificate2; $flags=[System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::MachineKeySet -bor [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable; $cert.Import($CertPath,$CertPassword,$flags) } } catch { Write-Warning ("Certificate not available: {0}" -f $_.Exception.Message) }
    if ($cert) { $ps1s=Get-ChildItem -LiteralPath $InstallDir -Filter '*.ps1' -File | Select-Object -ExpandProperty FullName; foreach($f in $ps1s){ try { $sig=Set-AuthenticodeSignature -FilePath $f -Certificate $cert -TimestampServer $TimestampServer -HashAlgorithm SHA256 -ErrorAction Stop; Write-Host ("Signed {0} [{1}]" -f $f,$sig.Status) -ForegroundColor DarkGreen } catch { Write-Warning ("Failed to sign {0}: {1}" -f $f,$_.Exception.Message) } } } else { Write-Warning 'Signing requested but no certificate available (provide -CertThumbprint or -CertPath).' }
  }
  # Finalize manifest
  try { $finalFiles = Get-ChildItem -LiteralPath $InstallDir -File | Where-Object { $_.Extension -in '.ps1','.cmd' } | Select-Object -ExpandProperty FullName; $written = Write-Manifest -ManifestPath $ManifestPath -InstallDir $InstallDir -RepoUrl $RepoUrl -Version $Version -InstalledFiles $finalFiles; Write-Host "Manifest written: $written" -ForegroundColor DarkGreen } catch { Write-Warning ("Failed to write manifest: {0}" -f $_.Exception.Message) }
  Invoke-PostAction -Action $PostAction
  if ($TranscriptStarted) { try { Stop-Transcript | Out-Null } catch {} }
  if ($LogPath) { Write-Host "Log written: $LogPath" -ForegroundColor DarkGreen }
}
#endregion
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
