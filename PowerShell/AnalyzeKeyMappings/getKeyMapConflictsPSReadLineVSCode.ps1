# Copyright (c) 2023 Matthias Wolf, Mawosoft.

<#
.SYNOPSIS
    Gets conflicting keymappings for PSReadLine and VSCode.
.OUTPUTS
    Objects containing the conflicting binding objects from both sources per first normalized chord.
#>

using namespace System
using namespace System.Collections.Generic

[CmdletBinding()]
[OutputType([psobject])]
param(
    # Paths to JSON files containing the key mappings.
    # The path for VSCode mappings is required, the path for PSReadLine is optional.
    # If the latter is not provided, the currently active mappings are used.
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidateCount(1, 2)]
    [string[]]$Path
)

. "$PSScriptRoot/KeyMapGerman.ps1"

$vscode = $null
$psreadline = $null
foreach ($_path in $Path) {
    $json = Get-Content $_path -Raw | ConvertFrom-Json
    if (-not $json) {
        throw "No content: $_path"
    }
    else {
        $p = $json[0].psobject.Properties
        if ($p['key'] -and $p['command']) {
            $vscode = $json
        }
        elseif ($p['Key'] -and $p['Function']) {
            $psreadline = $json
        }
        else {
            throw "Unknown file format: $_path"
        }
    }
}

if (-not $vscode) {
    throw 'No VSCode key mappings provided.'
}

if (-not $psreadline) {
    $psreadline = Get-PSReadLineKeyHandler
}

$vscode.Where({
        -not $_.psobject.Properties['when'] -or
        $_.command.Contains('terminal', [StringComparison]::OrdinalIgnoreCase) -or
        $_.when.Contains('terminal', [StringComparison]::OrdinalIgnoreCase)
    }).ForEach({
        [Chord[]]$chords = [KeyMapGerman]::ParseChord($_.key, ' ', $true)
        [PSCustomObject]@{
            FirstNormalized = $chords[0].Normalized
            Source          = 'VSCode'
            Item            = $_
        }
    }) +
$psreadline.ForEach({
        [Chord[]]$chords = [KeyMapGerman]::ParseChord($_.Key, ',', $true)
        [PSCustomObject]@{
            FirstNormalized = $chords[0].Normalized
            Source          = 'PSReadLine'
            Item            = $_
        }
    }) |
    Group-Object -Property FirstNormalized -CaseSensitive |
    ForEach-Object {
        if ($_.Count -gt 1) {
            $sources = $_.Group | Group-Object -Property Source -CaseSensitive
            if ($sources -is [array] -and $sources.Count -gt 1) {
                [PSCustomObject]@{
                    FirstNormalized  = $_.Name
                    $sources[0].Name = $sources[0].Group | Select-Object -ExpandProperty Item
                    $sources[1].Name = $sources[1].Group | Select-Object -ExpandProperty Item
                    # If we want to force arrays:
                    # $sources[0].Name = [object[]]($sources[0].Group | Select-Object -ExpandProperty Item)
                    # $sources[1].Name = [object[]]($sources[1].Group | Select-Object -ExpandProperty Item)
                }
            }
        }
    }
