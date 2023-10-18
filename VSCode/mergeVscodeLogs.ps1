# Copyright (c) 2023 Matthias Wolf, Mawosoft.

<#
.SYNOPSIS
    Merge multiple VSCode logs into a single log ordered by timestamps.
#>

#Requires -Version 7.3

using namespace System
using namespace System.Collections.Generic
using namespace System.IO
using namespace System.Text.RegularExpressions


[CmdletBinding()]
param(
    # Log file directory
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Path,

    # Log file names without extension. Wildcards are allowed.
    # Order determines how entries with identical timestamp are sorted.
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [SupportsWildcards()]
    [string[]]$LogName,

    # One or more window numbers. Default is 1.
    [ValidateNotNullOrEmpty()]
    [int[]]$Window = @(1),

    # Destination file. If omitted, output is sent to the pipe.
    [ValidateNotNullOrEmpty()]
    [string]$Destination,

    # Convert multi-line log entries to single line.
    [switch]$SingleLine
)

[List[FileInfo]]$candidateFiles = @()
[List[psobject]]$logFiles = @()

$candidateFiles.AddRange([FileInfo[]](Get-ChildItem $Path -File))

foreach ($windowNumber in $Window) {
    [string]$windowFolder = Join-Path $Path "window$windowNumber"
    if (Test-Path $windowFolder -PathType Container) {
        $candidateFiles.AddRange([FileInfo[]](Get-ChildItem $windowFolder -File -Recurse))
    }
}

foreach ($logPattern in $LogName) {
    for ([int]$i = 0; $i -lt $candidateFiles.Count; $i++) {
        [FileInfo]$fi = $candidateFiles[$i]
        if ($fi -and $fi.BaseName -like $logPattern -and $fi.Extension -eq '.log') {
            [string]$name = $fi.BaseName
            [DirectoryInfo]$parent = $fi.Directory
            while ($logFiles.Exists({ param($lf) $lf.Name -ceq $name }) -and $parent) {
                $name = $parent.Name + '/' + $name
                $parent = $parent.Parent
            }
            $logfiles.Add([PSCustomObject]@{
                    Name = $name
                    Path = $fi.FullName
                })
            $candidateFiles[$i] = $null
        }
    }
}

if ($logFiles.Count -lt 2) {
    throw 'At least two logfiles are required for merging.'
}

# Log entries from all files
[List[psobject]]$logEntries = @()

foreach ($logfile in $logFiles) {
    [string]$content = Get-Content $logFile.Path -Raw
    if (-not $content) { continue } # Can be empty
    [string]$name = $logFile.Name

    [Match]$m = [regex]::Match($content, '^(?<stamp>\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d\.\d\d\d) \[[A-Za-z]+\]')
    if (-not $m.Success) {
        Write-Warning "Skipping log with non-standard format $($logFile.Path)"
        continue
    }

    [string]$stamp = $m.Groups['stamp'].Value
    [int]$startPos = 0
    $m = [regex]::Match($content, '(?<eol>\r?\n)(?<stamp>\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d\.\d\d\d) \[[A-Za-z]+\]')
    for (; ; ) {
        [string]$entry = $m.Success ? $content.Substring($startPos, $m.Index - $startPos) : $content.Substring($startPos).TrimEnd("`r`n")
        if ($SingleLine) {
            $entry = [regex]::Replace($entry, '\r?\n', '¶')
        }
        $logEntries.Add([PSCustomObject]@{
                Name  = $name
                Stamp = $stamp
                Order = $i
                Entry = $entry
            })
        if (-not $m.Success) { break }
        $stamp = $m.Groups['stamp'].Value
        $startPos = $m.Index + $m.Groups['eol'].Length
        $m = $m.NextMatch()
    }
}

$logEntries.Sort({
        param($x, $y)
        [int]$r = $x.Stamp.CompareTo($y.Stamp)
        if ($r -ne 0) { return $r }
        return $x.Order.CompareTo($y.Order)
    })

[int]$logNamePadding = ($logEntries.Name | Measure-Object -Property Length -Maximum).Maximum + 1

[List[string]]$lines = $logEntries.ConvertAll[string]({
        param($e)
        return $e.Name.PadRight($logNamePadding) + $e.Entry
    })

if ($Destination) {
    $lines | Set-Content $Destination
}
else {
    $PSCmdlet.WriteObject($lines, $true)
}
