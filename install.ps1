<#
Copyright (C) 2025 Moko Consulting <hello@mokoconsulting.tech>

This file is part of a Moko Consulting project.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <https://www.gnu.org/licenses/>.

SPDX-License-Identifier: GPL-3.0-or-later
#>

param(
		[ValidateSet('User','Machine')]
		[string]$Scope = 'Machine'
)

# Resolve script directory robustly for right-click and CLI execution
$scriptFile = $PSCommandPath
if (-not $scriptFile -or [string]::IsNullOrWhiteSpace($scriptFile)) {
		$scriptFile = $MyInvocation.MyCommand.Path
}
if (-not $scriptFile -or [string]::IsNullOrWhiteSpace($scriptFile)) {
		throw 'Unable to determine script file path.'
}
$scriptDir = Split-Path -Path $scriptFile -Parent

# Ensure log file exists and prepend log entries
$logFile = Join-Path -Path $scriptDir -ChildPath 'install.log'
if (-not (Test-Path -LiteralPath $logFile)) {
		try { New-Item -ItemType File -Path $logFile -Force | Out-Null } catch { }
}
function Write-Log {
		param([string]$Message)
		try {
				$timestamp = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
				$entry = "[$timestamp] $Message"
				$existing = @()
				if (Test-Path -LiteralPath $logFile) {
						$existing = Get-Content -LiteralPath $logFile -ErrorAction SilentlyContinue
				}
				Set-Content -LiteralPath $logFile -Value ($entry, $existing)
		} catch {
				Write-Host "Logging failed: $Message" -ForegroundColor Yellow
		}
}

Write-Log ("Scope=$Scope User=$env:USERNAME — Starting installation")

# Detect best shell
$bestShell = if (Get-Command pwsh -ErrorAction SilentlyContinue) { 'pwsh' } else { 'powershell' }
Write-Log "Selected shell: $bestShell"

# Self-elevate if needed
if ($Scope -eq 'Machine' -and -not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
		Write-Log "Elevating to administrator for Machine scope"
		Start-Process $bestShell -Verb RunAs -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -File "{0}" -Scope {1}' -f $scriptFile, $Scope)
		exit
}

try {
		$scriptPath = Join-Path -Path $scriptDir -ChildPath 'Copy-PortablePath.ps1'
		Write-Log "Resolved script path: $scriptPath"

		if (-not (Test-Path -LiteralPath $scriptPath)) {
				Write-Log "ERROR: Copy-PortablePath.ps1 not found"
				throw 'Copy-PortablePath.ps1 not found in the current directory. Place install.ps1 next to Copy-PortablePath.ps1 and run again.'
		}

		$base = if ($Scope -eq 'Machine') { 'HKLM:\\Software\\Classes\\AllFilesystemObjects\\shell' } else { 'HKCU:\\Software\\Classes\\AllFilesystemObjects\\shell' }
		Write-Log "Using registry base: $base"

		function New-Verb {
				param(
						[Parameter(Mandatory)] [string]$Name,
						[Parameter(Mandatory)] [string]$Command,
						[string]$Icon = 'powershell.exe'
				)
				Write-Log "Creating verb: $Name"
				$verbKey = Join-Path -Path $base -ChildPath $Name
				$cmdKey  = Join-Path -Path $verbKey -ChildPath 'command'
				New-Item -Path $verbKey -Force | Out-Null
				Set-ItemProperty -Path $verbKey -Name '(default)' -Value $Name
				Set-ItemProperty -Path $verbKey -Name 'Icon' -Value $Icon
				New-Item -Path $cmdKey -Force | Out-Null
				Set-ItemProperty -Path $cmdKey -Name '(default)' -Value $Command
		}

		$quotedScript = '"' + $scriptPath + '"'
		$cmdRelative  = "$bestShell -NoProfile -ExecutionPolicy Bypass -File $quotedScript -Relative %*"
		$cmdAbsolute  = "$bestShell -NoProfile -ExecutionPolicy Bypass -File $quotedScript -Absolute %*"

		Write-Log "Command[Relative]= $cmdRelative"
		Write-Log "Command[Absolute]= $cmdAbsolute"

		New-Verb -Name 'Copy Relative Path' -Command $cmdRelative
		New-Verb -Name 'Copy Absolute Path' -Command $cmdAbsolute

		$relKey = Join-Path -Path $base -ChildPath 'Copy Relative Path'
		$absKey = Join-Path -Path $base -ChildPath 'Copy Absolute Path'
		if (-not (Test-Path -LiteralPath $relKey) -or -not (Test-Path -LiteralPath $absKey)) {
				Write-Log "ERROR: Registry keys not found after creation"
				throw 'One or more registry keys were not created. Installation failed.'
		}

		Write-Log "Installation successful — keys created: $relKey , $absKey"
		Write-Host '✅ Installed context menu entries:' -ForegroundColor Green
		Write-Host '  • Copy Relative Path'
		Write-Host '  • Copy Absolute Path'
		Write-Host ('   (script: {0})' -f $scriptPath)
		Write-Host "You can also run this installer by right-clicking it in Explorer and selecting 'Run with PowerShell'." -ForegroundColor Cyan
}
catch {
		Write-Log ("ERROR: {0}" -f $_.Exception.Message)
		Write-Host '❌ An error occurred:' -ForegroundColor Red
		Write-Host $_.Exception.Message -ForegroundColor Yellow
		Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
		exit 1
}
