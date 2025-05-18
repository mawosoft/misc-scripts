# Copyright (c) Matthias Wolf, Mawosoft.

<#
.SYNOPSIS
    Repairs shell integration for vscode-powershell.
.DESCRIPTION
    Repairs shell integration for vscode-powershell <= v2024.2.2 by creating a folder and a symlink.
    Needs to be run again after any update of VSCode >= 1.94.
    Requires admin rights. Runs on any PowerShell version or supported OS platform.
.NOTES
    VSCode 1.94++ moved the shell integration scripts to a different folder.
    As a result, the PowerShell Extension doesn't initialize correctly.
    Obsolete: Fixed in vscode-powershell v2024.4.0
#>

#Requires -Version 5.1

[CmdletBinding()]
param(
    # Path to VS Code if not on Windows or not default.
    [string]$VscodePath
)

if (-not $VscodePath -and ($PSVersionTable.PSVersion.Major -lt 6 -or $IsWindows)) {
    $VscodePath = Join-Path $env:ProgramFiles 'Microsoft VS Code'
}
if (-not (Test-Path -LiteralPath $VscodePath -PathType Container)) {
    throw 'Please specify VS Code install location with -VscodePath'
}

$terminalPath = Join-Path $VscodePath 'resources/app/out/vs/workbench/contrib/terminal'
$scriptsPath = Join-Path $terminalPath 'common/scripts'
if (-not (Test-Path -LiteralPath $scriptsPath -PathType Container)) {
    throw "Directory not found: $scriptsPath"
}
$browserPath = Join-Path $terminalPath 'browser'
if (-not (Test-Path -LiteralPath $browserPath -PathType Container)) {
    New-Item -ItemType Directory -Path $browserPath
}
$media = Join-Path '.' 'media'
if (-not (Test-Path -LiteralPath (Join-Path $browserPath $media) -PathType Container)) {
    # PowerShell has an issue with relative targets.
    Push-Location -LiteralPath $browserPath
    try {
        $target = Resolve-Path -LiteralPath $scriptsPath -Relative
        $target = Join-Path '.' $target
        New-Item -ItemType SymbolicLink -Path $media -Target $target
    }
    finally {
        Pop-Location
    }
}
