# Copyright (c) 2023 Matthias Wolf, Mawosoft.

<#
.SYNOPSIS
    Creates a new Powershell user profile.
.DESCRIPTION
    Creates a new Powershell user profile depending on the installed software.
.OUTPUTS
    [FileInfo] objects of the profile files if a scope has been specified.
    [string] Profile source code if no scope has been specified.
.NOTES
    - Currently only creates an AllHosts script.
    - Currently no special handling of PowerShell Desktop (5.1) vs. Core
#>

#Requires -Version 5.1

using namespace System
using namespace System.IO

[CmdletBinding(SupportsShouldProcess)]
[OutputType([System.IO.FileInfo], [string])]
param(
    # The user scope of the profile to create. The script picks the host scope itself.
    [ValidateSet('AllUsers', 'CurrentUser')]
    [string]$Scope,

    # Force overwriting existing scripts
    [switch]$Force
)

try {
    $null = Get-Variable 'foobar' -Scope 1 -ErrorAction Stop
}
catch [System.ArgumentOutOfRangeException] {
    throw 'Dot-sourcing this script is not allowed.'
}
catch {}

Set-StrictMode -Version 3.0
if (-not $PSBoundParameters.ContainsKey('ErrorAction')) {
    $ErrorActionPreference = 'Stop'
}

# Get content from source files
function Get-SourceContent {
    [OutputType([string])]
    param(
        # The directory containing the source files
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )
    # '.files just lists all file names to include in the desired order.
    [string]$filelist = Join-Path $Path '.files'
    [FileInfo[]]$files = $null
    if (Test-Path $filelist -PathType Leaf) {
        $files = Get-Content $filelist |
            ForEach-Object { $_.Trim() } |
            Where-Object { -not [string]::IsNullOrEmpty($_) -and -not $_.StartsWith([char]'#') } |
            ForEach-Object { Join-Path -Path $Path $_ } |
            Get-Item
    }
    else {
        $files = Get-ChildItem $Path -Filter '*.ps1'
    }
    Write-Verbose 'Source Files:'
    $files | Out-String | Write-Verbose
    $files | Get-Content -Raw
}

[string]$scriptGetProfileHelp = {
    <#
    .SYNOPSIS
        Gets help overview of profile functions and aliases
    .OUTPUTS
        Objects with Command and Parameters properties.
    #>
    function Get-ProfileHelp {
        [CmdletBinding()]
        [Alias('gprh')]
        [OutputType([psobject])]
        param()
        @('%ALIASES%') |
            Get-Command -ListImported |
            Select-Object @{n = 'Command'; e = 'DisplayName' }, @{n = 'Parameters'; e = '''''' }
        @('%FUNCTIONS%') |
            Get-Command -ListImported |
            Select-Object @{n = 'Command'; e = 'Name' }, @{n = 'Parameters'; e = { $_.ParameterSets -join [System.Environment]::NewLine } }
    }
}.ToString()

[object[]]$contentAllHosts = Get-SourceContent -Path "$PSScriptRoot/Common"

if (Test-Path 'env:VBOX_MSI_INSTALL_PATH') {
    $contentAllHosts += Get-SourceContent -Path "$PSScriptRoot/VirtualBoxHost"
}

[string]$vstudioPath = Join-Path $env:ProgramFiles 'Microsoft Visual Studio'
if (Test-Path $vstudioPath -PathType Container) {
    [string]$vstudioPath2 = Join-Path $vstudioPath '2022\Community\Common7'
    if (-not (Test-Path -Path (Join-Path $vstudioPath2 'IDE\devenv.exe') -PathType Leaf) -or
        -not (Test-Path -Path (Join-Path $vstudioPath2 'Tools\VsDevCmd.bat') -PathType Leaf)) {
        throw "The path '$vstudioPath' exists, but required files below are missing.`n" +
        'If the edition in use has changed, the profile source code needs to be updated.'
    }
    $contentAllHosts += Get-SourceContent -Path "$PSScriptRoot/Developer"
}

[object[]]$contentCurrentHost = @()

[string]$nl = [Environment]::NewLine
[string]$scriptAllHosts = $contentAllHosts -join $nl
[string]$scriptCurrentHost = $contentCurrentHost -join $nl

[psmoduleinfo]$tempModule = $null
[powershell]$posh = $null
try {
    $posh = [powershell]::Create($Host.Runspace.InitialSessionState).AddScript((
            @(
                "New-Module -ScriptBlock {$nl"
                $scriptAllHosts
                $scriptGetProfileHelp
                $scriptCurrentHost
                "${nl}Export-ModuleMember -Function * -Alias * $nl}$nl"
            ) -join ''
        ))
    $result = $posh.Invoke()
    if ($posh.HadErrors -or -not $result -or $result.Count -ne 1) {
        throw 'Failed to generate a temporary module for profile sources.'
    }
    $tempModule = $result[0]
}
finally {
    if ($posh) { $posh.Dispose() }
}

$scriptGetProfileHelp = $scriptGetProfileHelp.Replace('%ALIASES%',
    ($tempModule.ExportedAliases.Values.Name | Sort-Object) -join "', '")
$scriptGetProfileHelp = $scriptGetProfileHelp.Replace('%FUNCTIONS%',
    ($tempModule.ExportedFunctions.Values.Name | Sort-Object) -join "', '")
$scriptAllHosts += $nl + $scriptGetProfileHelp

if ($Scope) {
    [string]$profilePath = $PROFILE.$("${Scope}AllHosts")
    if ((Test-Path $profilePath -PathType Leaf) -and
        $scriptAllHosts.Equals((Get-Content $profilePath -Raw), [StringComparison]::Ordinal)) {
        Write-Verbose "'$profilePath' is already up-to-date."
    }
    else {
        New-Item -Path $profilePath -Value $scriptAllHosts -Force:$Force
    }

    $profilePath = $PROFILE.$("${Scope}CurrentHost")
    if ($scriptCurrentHost) {
        if ((Test-Path $profilePath -PathType Leaf) -and
            $scriptCurrentHost.Equals((Get-Content $profilePath -Raw), [StringComparison]::Ordinal)) {
            Write-Verbose "'$profilePath' is already up-to-date."
        }
        else {
            New-Item -Path $profilePath -Value $scriptCurrentHost -Force:$Force
        }
    }
}
else {
    $scriptAllHosts
    if ($scriptCurrentHost) {
        $scriptCurrentHost
    }
}
