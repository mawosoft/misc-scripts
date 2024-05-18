# Copyright (c) 2023-2024 Matthias Wolf, Mawosoft.

# dotnet Tab completion
# See https://learn.microsoft.com/en-us/dotnet/core/tools/enable-tab-autocomplete
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
    param($commandName, $wordToComplete, $cursorPosition)
    dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

# Visual Studio aliases
New-Alias -Name 'vstudio' -Value (Join-Path $env:ProgramFiles 'Microsoft Visual Studio\2022\Community\Common7\IDE\devenv.exe')
New-Alias -Name 'vsdevcmd' -Value (Join-Path $env:ProgramFiles 'Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat')
