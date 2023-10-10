# Copyright (c) 2023 Matthias Wolf, Mawosoft.

using namespace System
using namespace System.Collections.Generic

<#
.SYNOPSIS
    Key map for German standard keyboard layout.
#>
class KeyMapGerman {
    static [List[KeyMapGerman]]$CommonMap
    static [List[KeyMapGerman]]$NumPadMap
    [ConsoleKey]$ConsoleKey
    [char]$KeyChar
    [char]$KeyCharShift
    [char]$KeyCharAltGr

    static KeyMapGerman() {
        [KeyMapGerman]::CommonMap = @(
            [KeyMapGerman]::new('D0', '0', '=', '}')
            [KeyMapGerman]::new('D1', '1', '!')
            [KeyMapGerman]::new('D2', '2', '"', '²')
            [KeyMapGerman]::new('D3', '3', '§', '³')
            [KeyMapGerman]::new('D4', '4', '$')
            [KeyMapGerman]::new('D5', '5', '%')
            [KeyMapGerman]::new('D6', '6', '&')
            [KeyMapGerman]::new('D7', '7', '/', '{')
            [KeyMapGerman]::new('D8', '8', '(', '[')
            [KeyMapGerman]::new('D9', '9', ')', ']')
            [KeyMapGerman]::new('Oem1', 'ü', 'Ü')
            [KeyMapGerman]::new('Oem2', '#', '''')
            [KeyMapGerman]::new('Oem3', 'ö', 'Ö')
            [KeyMapGerman]::new('Oem4', 'ß', '?', '\')
            [KeyMapGerman]::new('Oem5', '^', '°')
            [KeyMapGerman]::new('Oem6', '´', '`')
            [KeyMapGerman]::new('Oem7', 'ä', 'Ä')
            # Oem8 doesn't exist on German keyboard
            [KeyMapGerman]::new('Oem102', '<', '>', '|')
            [KeyMapGerman]::new('OemPlus', '+', '*', '~')
            [KeyMapGerman]::new('OemComma', ',', ';')
            [KeyMapGerman]::new('OemMinus', '-', '_')
            [KeyMapGerman]::new('OemPeriod', '.', ':')
        )
        [KeyMapGerman]::NumPadMap = @(
            [KeyMapGerman]::new('NumPad0', '0')
            [KeyMapGerman]::new('NumPad1', '1')
            [KeyMapGerman]::new('NumPad2', '2')
            [KeyMapGerman]::new('NumPad3', '3')
            [KeyMapGerman]::new('NumPad4', '4')
            [KeyMapGerman]::new('NumPad5', '5')
            [KeyMapGerman]::new('NumPad6', '6')
            [KeyMapGerman]::new('NumPad7', '7')
            [KeyMapGerman]::new('NumPad8', '8')
            [KeyMapGerman]::new('NumPad9', '9')
            [KeyMapGerman]::new('Multiply', '*')
            [KeyMapGerman]::new('Add', '+')
            [KeyMapGerman]::new('Separator', ',')
            [KeyMapGerman]::new('Subtract', '-')
            [KeyMapGerman]::new('Decimal', ',')
            [KeyMapGerman]::new('Divide', '/')
        )

        for ([ConsoleKey]$k = [ConsoleKey]::A; $k -le [ConsoleKey]::Z; $k++) {
            [KeyMapGerman]::CommonMap.Add([KeyMapGerman]::new($k, $k -bor 0x20, $k))
        }
        [KeyMapGerman]::CommonMap.Find({ param([KeyMapGerman]$m) $m.ConsoleKey -eq [ConsoleKey]::Q }).KeyCharAltGr = '@'
        [KeyMapGerman]::CommonMap.Find({ param([KeyMapGerman]$m) $m.ConsoleKey -eq [ConsoleKey]::E }).KeyCharAltGr = '€'
        [KeyMapGerman]::CommonMap.Find({ param([KeyMapGerman]$m) $m.ConsoleKey -eq [ConsoleKey]::M }).KeyCharAltGr = 'µ'
        foreach ($k in [Enum]::GetValues([ConsoleKey])) {
            if (-not [KeyMapGerman]::CommonMap.Exists({ param([KeyMapGerman]$m) $m.ConsoleKey -eq $k }) -and
                -not [KeyMapGerman]::NumPadMap.Exists({ param([KeyMapGerman]$m) $m.ConsoleKey -eq $k })) {
                [KeyMapGerman]::CommonMap.Add([KeyMapGerman]::new($k))
            }
        }

    }

    <#
    .SYNOPSIS
        Find keymap entry for given key or key name.
    #>
    static [KeyMapGerman]Find([string]$key, [bool]$noNumPad) {
        if (-not $key) { return $null }
        if ($key.Length -gt 1) {
            if ($key.Length -eq 5 -and $key.StartsWith('Num ', [StringComparison]::OrdinalIgnoreCase)) {
                [char]$c = $key[4]
                [KeyMapGerman]$km = [KeyMapGerman]::NumPadMap.Find({ param([KeyMapGerman]$m) $m.KeyChar -ceq $c })
                if ($km) {
                    $key = $km.ConsoleKey.ToString()
                }
            }
            elseif ($key.StartsWith('NumPad', [StringComparison]::OrdinalIgnoreCase)) {
                if ($key.Length -gt 6 -and $key[6] -ceq '_') {
                    $key = $key.Remove(6, 1)
                }
                if ($key.Length -gt 6 -and $key[6] -cnotlike '[0-9]') {
                    $key = $key.Substring(6)
                }
            }
            elseif ($key.StartsWith('Oem', [StringComparison]::OrdinalIgnoreCase)) {
                if ($key.Length -gt 3 -and $key[3] -ceq '_') {
                    $key = $key.Remove(3, 1)
                }
            }
            elseif ($key -in 'down', 'up', 'left', 'right') {
                $key += 'Arrow'
            }
            elseif ($key.EndsWith(' Arrow', [StringComparison]::OrdinalIgnoreCase)) {
                $key = $key.Remove($Key.Length - 6, 1)
            }
            else {
                switch ($key) {
                    'space' { $key = 'Spacebar'; break; }
                    'Bkspce' { $key = 'Backspace'; break; }
                    'Del' { $key = 'Delete'; break; }
                    'Esc' { $key = 'Escape'; break; }
                    'Ins' { $key = 'Insert'; break; }
                    'PgDn' { $key = 'PageDown'; break; }
                    'PgUp' { $key = 'PageUp'; break; }
                    'Break' { $key = 'Pause'; break; }
                    Default {}
                }
            }
        }
        if ($key.Length -gt 1) {
            [ConsoleKey]$ck = $key
            [KeyMapGerman]$km = [KeyMapGerman]::NumPadMap.Find({ param([KeyMapGerman]$m) $m.ConsoleKey -eq $ck })
            if ($km) {
                if (-not $noNumPad) { return $km }
                $key = $km.KeyChar
            }
            else {
                $km = [KeyMapGerman]::CommonMap.Find({ param([KeyMapGerman]$m) $m.ConsoleKey -eq $ck })
                if ($km) { return $km }
            }
        }
        if ($key.Length -eq 1) {
            [char]$c = $key[0]
            [KeyMapGerman]$km = [KeyMapGerman]::CommonMap.Find({ param([KeyMapGerman]$m) $m.KeyChar -ceq $c })
            if ($km) { return $km }
            [KeyMapGerman]$km = [KeyMapGerman]::CommonMap.Find({ param([KeyMapGerman]$m) $m.KeyCharShift -ceq $c })
            if ($km) { return $km }
            return [KeyMapGerman]::CommonMap.Find({ param([KeyMapGerman]$m) $m.KeyCharAltGr -ceq $c })
        }
        return $null
    }

    <#
    .SYNOPSIS
        Parse one or more chords (key combo with modifiers) into [Chord] objects.
    .PARAMETER $chord
        The chord to parse, e.g. 'Ctrl+k,Ctrl+j'
    .PARAMETER $separator
        Separator for multiple chords.
        This becomes part of a regex, so escape appropriately.
    .PARAMETER $noNumPad
        If true, maps any numpad keys defined in the chord to their standard block counterparts,
        e.g. NumPad0 -> D0, Multiply -> *
    #>
    static [Chord[]]ParseChord([string]$chord, [string]$separator, [bool]$noNumPad) {
        [string[]]$parts = [regex]::Split($chord, '(?<!\+)' + $separator)
        return $parts.ForEach({ [Chord]::new($_, $noNumPad) })
    }

    <#
    .SYNOPSIS
        Parse the chord defined in a binding object into [Chord] objects.
    .PARAMETER $bindingObject
        Single entry from imported key bindings (usually from a JSON file).
        Bindings from PSReadline, VSCode, and Visual Studio are recognized automatically.
    .PARAMETER $noNumPad
        If true, maps any numpad keys defined in the chord to their standard block counterparts,
        e.g. NumPad0 -> D0, Multiply -> *
    #>
    static [Chord[]]ParseChord([psobject]$bindingObject, [bool]$noNumPad) {
        $p = $bindingObject.psobject.Properties
        if ($p['KeyBinding'] -and $p['Scope']) {
            # Visual Studio
            return [KeyMapGerman]::ParseChord($p['KeyBinding'].Value, ', ', $noNumpad)
        }
        elseif ($p['key'] -and $p['command']) {
            # VSCode
            return [KeyMapGerman]::ParseChord($p['key'].Value, ' ', $noNumpad)
        }
        elseif ($p['Key'] -and $p['Function']) {
            # PSReadline
            return [KeyMapGerman]::ParseChord($p['Key'].Value, ',', $noNumpad)
        }
        throw [ArgumentException]::new($null, 'bindingObject')
    }

    KeyMapGerman() {
    }
    KeyMapGerman([ConsoleKey]$consoleKey) {
        $this.ConsoleKey = $consoleKey
    }
    KeyMapGerman([ConsoleKey]$consoleKey, [char]$keyChar) {
        $this.ConsoleKey = $consoleKey
        $this.KeyChar = $keyChar
    }
    KeyMapGerman([ConsoleKey]$consoleKey, [char]$keyChar, [char]$keyCharShift) {
        $this.ConsoleKey = $consoleKey
        $this.KeyChar = $keyChar
        $this.KeyCharShift = $keyCharShift
    }
    KeyMapGerman([ConsoleKey]$consoleKey, [char]$keyChar, [char]$keyCharShift, [char]$keyCharAltGr) {
        $this.ConsoleKey = $consoleKey
        $this.KeyChar = $keyChar
        $this.KeyCharShift = $keyCharShift
        $this.KeyCharAltGr = $keyCharAltGr
    }

    <#
    .SYNOPSIS
        Gets a normalized string representation of the key map entry with the specified
        modifiers applied.
    #>
    [string]GetNormalized([ConsoleModifiers]$modifiers, [bool]$windowsKeyModifier) {
        [string]$s = ''
        if ($modifiers.HasFlag([ConsoleModifiers]::Control)) {
            $s += 'Ctrl+'
        }
        if ($modifiers.HasFlag([ConsoleModifiers]::Alt)) {
            $s += 'Alt+'
        }
        if ($modifiers.HasFlag([ConsoleModifiers]::Shift)) {
            $s += 'Shift+'
        }
        if ($windowsKeyModifier) {
            $s += 'Win+'
        }
        if ($this.ConsoleKey -in [System.ConsoleKey]::A..[System.ConsoleKey]::Z) {
            return $s + $this.KeyChar
        }
        else {
            return $s + $this.ConsoleKey.ToString()
        }
    }

    <#
    .SYNOPSIS
        Checks if the key map entry is valid with the given modifiers.
    .NOTES
        For example, Ctrl+Alt+? doesn't work on a German keyboard because it really is
        Ctrl+Alt+Shift+Oem4, which has an AltGr character (ß ? \).
    #>
    [bool]IsValid([ConsoleModifiers]$modifiers) {
        if (-not $modifiers -or -not $this.KeyChar -or
            -not $modifiers.HasFlag([System.ConsoleModifiers]'Control, Alt, Shift')) {
            return $true
        }
        return -not $this.KeyCharAltGr
    }
}

<#
.SYNOPSIS
    Contains information about a parsed chord.
#>
class Chord {
    [string]$Original
    [string]$OriginalKey
    [string]$Normalized
    [KeyMapGerman]$KeyMap
    [ConsoleModifiers]$Modifiers
    [bool]$WindowsKeyModifier
    [bool]$IsValid

    Chord() {}

    Chord([string]$chord, [bool]$noNumPad) {
        $this.Original = $chord
        [bool]$invalid = $false
        [string[]]$keys = [regex]::Split($chord, '(?<!\+)\+')
        [int]$n = $keys.Length - 1
        for ([int]$i = 0; $i -lt $n; $i++) {
            switch ($keys[$i]) {
                'shift' { $this.Modifiers = $this.Modifiers -bor [ConsoleModifiers]::Shift; break }
                'alt' { $this.Modifiers = $this.Modifiers -bor [ConsoleModifiers]::Alt; break }
                'ctrl' { $this.Modifiers = $this.Modifiers -bor [ConsoleModifiers]::Control; break }
                'win' { $this.WindowsKeyModifier = $true; break }
                Default { $invalid = $true }
            }
        }
        $this.OriginalKey = $keys[$keys.Length - 1]
        $this.KeyMap = [KeyMapGerman]::Find($this.OriginalKey, $noNumPad)
        if ($this.KeyMap) {
            if ($this.OriginalKey.Length -eq 1) {
                if ($this.OriginalKey[0] -ceq $this.KeyMap.KeyCharShift) {
                    $this.Modifiers = $this.Modifiers -bor [ConsoleModifiers]::Shift;
                }
                elseif ($this.OriginalKey[0] -ceq $this.KeyMap.KeyCharAltGr) {
                    $this.Modifiers = $this.Modifiers -bor [ConsoleModifiers]::Control -bor [ConsoleModifiers]::Alt;
                }
            }
            $this.Normalized = $this.KeyMap.GetNormalized($this.Modifiers, $this.WindowsKeyModifier)
            if (-not $invalid) {
                $this.IsValid = $this.KeyMap.IsValid($this.Modifiers)
            }
        }
    }
}
