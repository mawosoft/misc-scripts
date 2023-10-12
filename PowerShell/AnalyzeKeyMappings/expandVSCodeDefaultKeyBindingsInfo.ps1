# Copyright (c) 2023 Matthias Wolf, Mawosoft.

<#
.SYNOPSIS
    Expands the VSCode default keybindings with infos about keybindings not sent to the shell.
#>

using namespace System
using namespace System.Collections.Generic

[CmdletBinding()]
param(
    # Path to VSCode default keybindings JSON file.
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$DefaultKeyBindingPath,

    # Path to VSCode default settings JSON file.
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$DefaultSettingsPath,

    # Path to destination JSON file.
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Destination,
    [switch]$Force
)

$keybindings = Get-Content $DefaultKeyBindingPath -Raw | ConvertFrom-Json
[Queue[string]]$settings = Get-Content $DefaultSettingsPath
[HashSet[string]]$defaultSkippedCommands = @{}

while ($settings.Count -gt 0 -and
    -not $settings.Dequeue().Contains(
        'Default Skipped Commands:',
        [StringComparison]::OrdinalIgnoreCase)) {
    <# do nothing #>
}

while ($settings.Count -gt 0) {
    [string]$line = $settings.Dequeue().Trim()
    if ($line.Length -eq 0) { continue }
    if (-not $line.StartsWith('//')) { break }
    $line = $line.Trim("/- `t")
    if ($line.Length -gt 0) {
        $null = $defaultSkippedCommands.Add($line)
    }
}

foreach ($binding in $keybindings) {
    if ($defaultSkippedCommands.Contains($binding.command)) {
        $binding.psobject.Properties.Add([psnoteproperty]::new('skipShell', $true))
    }
}

$keyBindings | ConvertTo-Json | New-Item -Path $Destination -Force:$Force
