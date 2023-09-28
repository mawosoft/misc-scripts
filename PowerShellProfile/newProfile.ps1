# Copyright (c) 2023 Matthias Wolf, Mawosoft.

<#
.SYNOPSIS
    Creates a new Powershell profile of the selected type and dot-sources the given files or copies their content.
.OUTPUTS
    [FileInfo] object of the profile.
#>

#Requires -Version 5.1

[CmdletBinding(SupportsShouldProcess)]
[OutputType([System.IO.FileInfo])]
param(
    # The paths to the scripts to dot source or copy.
    # If not specified, the scripts are determined automatically
    [ValidateNotNullOrEmpty()]
    [string[]]$Path,

    # The scope of the profile to create.
    [ValidateSet('AllUsersAllHosts', 'AllUsersCurrentHost', 'CurrentUserAllHosts', 'CurrentUserCurrentHost')]
    [string]$Scope = 'CurrentUserAllHosts',

    # Whether to dot source or copy the script into the profile.
    [ValidateSet('DotSource', 'SetContent')]
    [string]$Mode = 'DotSource',

    # Force overwriting an existing script
    [switch]$Force
)

Set-StrictMode -Version 3.0

if (-not $Path) {
    $Path = @("$PSScriptRoot/profileCommon.ps1")
    if (Test-Path 'env:VBOX_MSI_INSTALL_PATH') {
        $Path += "$PSScriptRoot/profileVBoxHost.ps1"
    }
    if (Test-Path 'C:\Program Files\Microsoft Visual Studio\2022') {
        $Path += "$PSScriptRoot/profileDeveloper.ps1"
    }
    
}

[System.Collections.ArrayList]$contents = @()

if ($Mode -eq 'DotSource') {
    foreach ($_path in $Path) {
        $_path = Resolve-Path $_path
        Write-Verbose "Dot-sourcing $_path"
        $null = $contents.Add(". '$_path'")
    }
}
else {
    foreach ($_path in $Path) {
        # Also ensures $Path is valid
        $_path = Resolve-Path $_path
        Write-Verbose "Copying content $_path"
        $null = $contents.Add((Get-Content $_path -Raw))
    }
}

[string]$profilePath = $PROFILE.$($Scope)

New-Item -Path $profilePath -Value ($contents -join [System.Environment]::NewLine) -Force:$Force
