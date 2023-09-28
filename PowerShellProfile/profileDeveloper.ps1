# Copyright (c) 2023 Matthias Wolf, Mawosoft.

# Visual Studio alias

if (Test-Path 'C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\devenv.exe') {
    Set-Alias -Scope Global -Name 'vstudio' -Value 'C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\devenv.exe'
}

if (Test-Path 'C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat') {
    Set-Alias -Scope Global -Name 'vsdevcmd' -Value 'C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat'
    Set-Alias -Scope Global -Name 'ipvsd' -Value 'Import-VsDevCmd'

    function global:Import-VsDevCmd {
        <#
        .SYNOPSIS
            Imports the VsDevCmd environment variables
        #>
        [CmdletBinding()] param()
        Import-BatchEnvironment (Get-Alias 'vsdevcmd').Definition
    }
}

# dotnet Tab completion
# See https://learn.microsoft.com/en-us/dotnet/core/tools/enable-tab-autocomplete
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
     param($commandName, $wordToComplete, $cursorPosition)
         dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
         }
 }


<#
.SYNOPSIS
    Sets MSBuild environment variables to auto-generate binlogs
#>
function global:Set-BinlogEnvironment {
    [CmdletBinding()]
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
    $env:MSBUILDLOGALLENVIRONMENTVARIABLES = if ($LogAllEnvVars) { 'true' } else { $null }
    $env:MSBUILDDEBUGPATH = if ($Path) { $Path } else { $null }
}

<#
.SYNOPSIS
    Clears the MSBuild environment variables for binlog auto-generation
#>
function global:Clear-BinlogEnvironment {
    [CmdletBinding()]
    param()

    $env:MSBuildDebugEngine = $null
    $env:MSBUILDLOGTASKINPUTS = $null
    $env:MSBUILDTARGETOUTPUTLOGGING = $null
    $env:MSBUILDLOGIMPORTS = $null
    $env:MSBUILDLOGALLENVIRONMENTVARIABLES = $null
    $env:MSBUILDDEBUGPATH = $null
}
