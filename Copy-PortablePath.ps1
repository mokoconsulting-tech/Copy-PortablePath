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

param (
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Path,

    [switch]$Relative,
    [switch]$Absolute,

    # Optional fixed base directory for relative mode. If omitted, the script
    # will try to auto-detect a project root (e.g., .git) or fall back to a
    # common parent directory.
    [string]$Base,

    # Convert absolute paths like C:/foo to /c/foo (MSYS/WSL-like style)
    [switch]$MsysStyle,

    # Suppress console output (clipboard is still set)
    [switch]$Quiet
)

<#
    Copy-PortablePath.ps1
    ------------------------------------------------------------
    Copies selected file/folder paths to the clipboard using portable
    forward slashes ('/'). Supports two modes:
      -Relative  -> paths relative to a base (auto-detected or provided)
      -Absolute  -> full absolute paths (default when no switch given)

    Features:
      • Multi-selection aware (Explorer passes %*)
      • Auto project-root detection (.git, .hg, .svn, package.json, etc.)
      • Optional MSYS/WSL style (/c/path)
      • Uses single quotes for strings in this script per preference

    Examples:
      powershell -File Copy-PortablePath.ps1 -Relative %*
      powershell -File Copy-PortablePath.ps1 -Absolute %*
      powershell -File Copy-PortablePath.ps1 -Relative -Base 'J:\\Shared drives' %*
      powershell -File Copy-PortablePath.ps1 -Absolute -MsysStyle %*
#>

$ErrorActionPreference = 'Stop'

# Default to absolute if neither flag is provided
if (-not $Relative -and -not $Absolute) { $Absolute = $true }

function Get-CommonRoot {
    param([string[]]$paths)
    if (-not $paths -or $paths.Count -eq 0) { return $null }
    try {
        $split = $paths | ForEach-Object { (Resolve-Path -LiteralPath $_).Path -split '\\' }
    } catch { return $null }
    $first = $split[0]
    $i = 0
    while ($true) {
        if ($i -ge $first.Count) { break }
        $seg = $first[$i]
        if ($split | Where-Object { $_.Count -le $i -or $_[$i] -ne $seg }) { break }
        $i++
    }
    if ($i -eq 0) { return $null }
    return ($first[0..($i-1)] -join '\\')
}

function Find-ProjectRoot {
    param([string]$start)
    $cur = (Resolve-Path -LiteralPath $start).Path
    if (Test-Path -LiteralPath $cur -PathType Leaf) { $cur = Split-Path -LiteralPath $cur -Parent }
    while ($true) {
        foreach ($m in '.git','.hg','.svn','package.json','.editorconfig','pyproject.toml') {
            if (Test-Path -LiteralPath (Join-Path -Path $cur -ChildPath $m)) { return $cur }
        }
        $parent = Split-Path -LiteralPath $cur -Parent
        if (-not $parent -or $parent -eq $cur) { break }
        $cur = $parent
    }
    return $null
}

function To-Portable {
    param([string]$p, [switch]$msys)
    $p = $p -replace '\\','/'
    if ($msys) {
        if ($p -match '^(?<drive>[A-Za-z]):/(.*)$') {
            $p = '/' + $Matches['drive'].ToLower() + '/' + $Matches[2]
        }
    }
    return $p
}

function Make-Relative {
    param([string]$basePath, [string]$targetPath)
    try {
        $uriBase   = [Uri]((Resolve-Path -LiteralPath $basePath).Path + '\\')
        $uriTarget = [Uri]((Resolve-Path -LiteralPath $targetPath).Path)
        $rel = $uriBase.MakeRelativeUri($uriTarget).ToString()
        $rel = [Uri]::UnescapeDataString($rel)
        if (-not ($rel.StartsWith('.') -or $rel.StartsWith('/'))) { $rel = './' + $rel }
        return $rel
    } catch {
        return (Resolve-Path -Relative -LiteralPath $targetPath)
    }
}

# Resolve incoming selection(s). If none were provided, try $args as fallback
if (-not $Path -or $Path.Count -eq 0) { $Path = $args }

$resolved = @()
foreach ($item in $Path) {
    try {
        if ([string]::IsNullOrWhiteSpace($item)) { continue }
        $resolved += (Resolve-Path -LiteralPath $item).Path
    } catch { }
}
if ($resolved.Count -eq 0) {
    if (-not $Quiet) { Write-Host 'No valid paths provided.' -ForegroundColor Yellow }
    exit 0
}

# Determine base for relative mode
$basePath = $null
if ($Relative) {
    if ($Base) {
        $basePath = (Resolve-Path -LiteralPath $Base).Path
    } else {
        $auto = Find-ProjectRoot -start $resolved[0]
        if ($auto) { $basePath = $auto }
        if (-not $basePath) { $basePath = Get-CommonRoot -paths $resolved }
        if (-not $basePath) { $basePath = Split-Path -LiteralPath $resolved[0] -Parent }
    }
}

$out = New-Object System.Collections.Generic.List[string]
foreach ($p in $resolved) {
    $target = $p
    if ($Relative) {
        $target = Make-Relative -basePath $basePath -targetPath $p
    } else {
        $target = (Resolve-Path -LiteralPath $p).Path
    }
    $out.Add((To-Portable -p $target -msys:$MsysStyle))
}

$final = ($out -join [Environment]::NewLine)
Set-Clipboard -Value $final

if (-not $Quiet) {
    Write-Host ('Copied {0} path(s) to clipboard.' -f $out.Count)
    if ($Relative) { Write-Host ('Base: {0}' -f (To-Portable -p $basePath)) }
}
