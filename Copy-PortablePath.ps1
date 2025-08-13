param (
    [string[]]$Path,
    [switch]$Relative,
    [switch]$Absolute,
    [string]$Base,
    [switch]$MsysStyle # Optional: convert C:/... to /c/... for MSYS/WSL-like style
)

# If neither switch is provided, default to Absolute
if (-not $Relative -and -not $Absolute) { $Absolute = $true }

function Get-CommonRoot([string[]]$paths) {
    if (-not $paths -or $paths.Count -eq 0) { return $null }
    $parts = $paths | ForEach-Object { (Resolve-Path $_).Path -split '\\' }
    $first = $parts[0]
    $i = 0
    while ($true) {
        if ($i -ge $first.Count) { break }
        $segment = $first[$i]
        if ($parts | Where-Object { $_.Count -le $i -or $_[$i] -ne $segment }) { break }
        $i++
    }
    if ($i -eq 0) { return $null }
    return ($first[0..($i-1)] -join '\\')
}

function Find-ProjectRoot([string]$start) {
    $cur = (Resolve-Path $start).Path
    if (Test-Path -LiteralPath $cur -PathType Leaf) { $cur = Split-Path -LiteralPath $cur -Parent }
    while ($true) {
        foreach ($marker in '.git','.hg','.svn','package.json','.editorconfig','pyproject.toml') {
            if (Test-Path -LiteralPath (Join-Path $cur $marker)) { return $cur }
        }
        $parent = Split-Path -LiteralPath $cur -Parent
        if (-not $parent -or $parent -eq $cur) { break }
        $cur = $parent
    }
    return $null
}

function To-Portable([string]$p, [switch]$msys) {
    $p = $p -replace '\\','/'
    if ($msys) {
        # Convert C:/path -> /c/path (MSYS/WSL-like)
        if ($p -match '^(?<drive>[A-Za-z]):/(.*)$') {
            $p = '/' + ($Matches['drive'].ToLower()) + '/' + $Matches[2]
        }
    }
    return $p
}

# Resolve selected items
$resolved = @()
foreach ($item in $Path) {
    try { $resolved += (Resolve-Path -LiteralPath $item).Path } catch { }
}
if ($resolved.Count -eq 0) { exit 0 }

# Determine base for relative mode
$basePath = $null
if ($Relative) {
    if ($Base) {
        $basePath = (Resolve-Path -LiteralPath $Base).Path
    } else {
        $auto = Find-ProjectRoot -start $resolved[0]
        if ($auto) {
            $basePath = $auto
        } else {
            $common = Get-CommonRoot -paths $resolved
            $basePath = if ($common) { $common } else { Split-Path -LiteralPath $resolved[0] -Parent }
        }
    }
}

$out = @()
foreach ($p in $resolved) {
    $target = $p
    if ($Relative) {
        try {
            $uriBase = New-Object System.Uri((Resolve-Path -LiteralPath $basePath).Path + '\\')
            $uriTarget = New-Object System.Uri((Resolve-Path -LiteralPath $p).Path)
            $rel = $uriBase.MakeRelativeUri($uriTarget).ToString()
            $target = [uri]::UnescapeDataString($rel)
        } catch {
            $target = (Resolve-Path -Relative -LiteralPath $p)
        }
        if (-not ($target.StartsWith('.') -or $target.StartsWith('/'))) {
            $target = './' + $target
        }
    } else {
        $target = (Resolve-Path -LiteralPath $p).Path
    }
    $out += (To-Portable -p $target -msys:$MsysStyle)
}

# Join with newlines and copy to clipboard
$final = ($out -join [Environment]::NewLine)
Set-Clipboard -Value $final

# Optional toast in console when run interactively
if ($Host.Name -notmatch 'Default Host') {
    Write-Host ('Copied {0} path(s) to clipboard.' -f $out.Count)
}