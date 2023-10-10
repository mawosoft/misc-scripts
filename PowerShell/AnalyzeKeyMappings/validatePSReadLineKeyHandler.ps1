# Copyright (c) 2023 Matthias Wolf, Mawosoft.

<#
.SYNOPSIS
    Validates PSReadLine keybindings for German keyboard layout.
.OUTPUTS
    [Chord] objects for invalid keybindings.
.NOTES
    Currently (PSReadLine 2.3.4) returns 'Ctrl+Alt+?'.
#>
[CmdletBinding()]
[OutputType([object])]
param()

. "$PSScriptRoot/KeyMapGerman.ps1"

$allHandlers = Get-PSReadLineKeyHandler
$allHandlers | ForEach-Object {
    [Chord[]]$chords = [KeyMapGerman]::ParseChord($_, $true)
    if ($chords.IsValid -contains $false) {
        $chords
    }
}
