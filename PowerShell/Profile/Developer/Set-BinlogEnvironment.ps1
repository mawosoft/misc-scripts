# Copyright (c) Matthias Wolf, Mawosoft.

<#
.SYNOPSIS
    Sets MSBuild environment variables to auto-generate binlogs.
#>
function Set-BinlogEnvironment {
    [Alias('sbl')]
    param(
        # Directory path to store the binlogs, defaults to .\MSBuild_Logs
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        # Granular settings for property tracking. Reassignment is enabled by default.
        [ValidateSet('Reassignment', 'InitialValue', 'ReadEnvironment', 'ReadUnitialized')]
        [string[]]$PropertyTracking,

        # Enable full property tracking.
        [switch]$TrackProperties,

        # Include all environment variables, not just used ones.
        [switch]$LogAllEnvVars,

        # Set all environment variables, even if implicitly enabled.
        [switch]$SetAll
    )

    if (-not $Path) { $Path = '.\MSBuild_Logs' }
    $Path = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine((Get-Location -PSProvider 'FileSystem').Path, $Path))

    $PropertyTrackingSetting = 0
    if ($TrackProperties) {
        $PropertyTrackingSetting = 15
    }
    elseif ($PropertyTracking) {
        if ($PropertyTracking -contains 'Reassignment') { $PropertyTrackingSetting = $PropertyTrackingSetting -bor 1 }
        if ($PropertyTracking -contains 'InitialValue') { $PropertyTrackingSetting = $PropertyTrackingSetting -bor 2 }
        if ($PropertyTracking -contains 'ReadEnvironment') { $PropertyTrackingSetting = $PropertyTrackingSetting -bor 4 }
        if ($PropertyTracking -contains 'ReadUnitialized') { $PropertyTrackingSetting = $PropertyTrackingSetting -bor 8 }
    }
    elseif ($SetAll) {
        $PropertyTrackingSetting = 1
    }

    $env:MSBuildDebugEngine = 1
    $env:MSBUILDDEBUGPATH = $Path

    if ($PropertyTrackingSetting -ne 0) {
        $env:MsBuildLogPropertyTracking = $PropertyTrackingSetting
    }
    if ($LogAllEnvVars) {
        $env:MSBUILDLOGALLENVIRONMENTVARIABLES = 'true'
    }

    if ($SetAll) {
        # BuildManager enables this internally if MSBuildDebugEngine is enabled.
        $env:MSBUILDLOGTASKINPUTS = 1 # Only '1' enables

        # Binlogger sets these automatically as env vars and Traits/Traits.EscapeHatches.
        $env:MSBUILDTARGETOUTPUTLOGGING = 'true'
        $env:MSBUILDLOGIMPORTS = 1
        #$env:MSBUILDBINARYLOGGERENABLED = 'true' # Tells some NuGet tasks that Binlogger is enabled. Only 'true'  enables.

        $env:MSBUILDLOGPROPERTIESANDITEMSAFTEREVALUATION = 1 # Enabled by default. 0/false disables.
    }
}
