# Copyright (c) 2023 Matthias Wolf, Mawosoft.

<#
.SYNOPSIS
    Verifies consistency of PSReadLine keybindings.
.OUTPUTS
    Compare-Object results
.NOTES
    Currently (PSReadLine 2.3.4) returns 'Ctrl+Alt+?'.
#>
[CmdletBinding()]
[OutputType([psobject])]
param()
$allHandlers = Get-PSReadLineKeyHandler
[string[]]$allKeys = $allHandlers | Select-Object -ExpandProperty Key
$individualHandlers = Get-PSReadLineKeyHandler -Chord $allKeys
Compare-Object -ReferenceObject $allHandlers -DifferenceObject $individualHandlers -Property Key, Function, Group, Description
