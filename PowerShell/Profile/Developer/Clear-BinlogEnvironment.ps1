# Copyright (c) 2023 Matthias Wolf, Mawosoft.

<#
.SYNOPSIS
    Clears the MSBuild environment variables for binlog auto-generation
#>
function Clear-BinlogEnvironment {
    param()

    $env:MSBuildDebugEngine = $null
    $env:MSBUILDLOGTASKINPUTS = $null
    $env:MSBUILDTARGETOUTPUTLOGGING = $null
    $env:MSBUILDLOGIMPORTS = $null
    $env:MSBUILDLOGALLENVIRONMENTVARIABLES = $null
    $env:MSBUILDDEBUGPATH = $null
}
