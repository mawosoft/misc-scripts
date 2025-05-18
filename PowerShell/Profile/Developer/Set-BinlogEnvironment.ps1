# Copyright (c) Matthias Wolf, Mawosoft.

<#
.SYNOPSIS
    Sets MSBuild environment variables to auto-generate binlogs
#>
function Set-BinlogEnvironment {
    [Alias('sbl')]
    param(
        # Binlog will include all environment variables, not just used ones.
        [switch]$LogAllEnvVars,

        # Directory path to store the binlogs, defaults to .\MSBuild_Logs
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    $env:MSBuildDebugEngine = 1
    # Fix incomplete binlogs in MSBuild <=17.3.x. See https://github.com/mawosoft/Mawosoft.Extensions.BenchmarkDotNet/issues/146
    $env:MSBUILDLOGTASKINPUTS = 1
    $env:MSBUILDTARGETOUTPUTLOGGING = 'true'
    $env:MSBUILDLOGIMPORTS = 1
    # PowerShell 5.1 compat: $bool ? 'yes' : 'no'  --> if ($bool) { 'yes' } else { 'no' }
    $env:MSBUILDLOGALLENVIRONMENTVARIABLES = if ($LogAllEnvVars) { 'true' } else { $null }
    $env:MSBUILDDEBUGPATH = if ($Path) { $Path } else { $null }
}
