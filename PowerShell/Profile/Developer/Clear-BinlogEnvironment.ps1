# Copyright (c) Matthias Wolf, Mawosoft.

<#
.SYNOPSIS
    Clears the MSBuild environment variables for binlog auto-generation
#>
function Clear-BinlogEnvironment {
    [Alias('clbl')]
    param()

    $env:MSBuildDebugEngine = $null
    $env:MSBUILDDEBUGPATH = $null
    $env:MsBuildLogPropertyTracking = $null
    $env:MSBUILDLOGALLENVIRONMENTVARIABLES = $null

    $env:MSBUILDLOGTASKINPUTS = $null
    $env:MSBUILDTARGETOUTPUTLOGGING = $null
    $env:MSBUILDLOGIMPORTS = $null
    $env:MSBUILDLOGPROPERTIESANDITEMSAFTEREVALUATION = $null
}
