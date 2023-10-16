# Copyright (c) 2023 Matthias Wolf, Mawosoft.

Set-StrictMode -Version 3
$ErrorActionPreference = 'Stop'

# One history across all hosts per user
Set-PSReadLineOption -HistorySavePath (Join-Path (
        [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::MyDocuments)
    ) 'PowerShell\PSReadLine\AllHosts_history.txt' )
# Can be toggled with F2.
Set-PSReadLineOption -PredictionViewStyle ListView

Set-PSReadLineKeyHandler -Chord Ctrl+F1 -BriefDescription 'Online Help' -Description 'Show online help for the command under or before the cursor.' -ScriptBlock {
    param($key, $arg)
    [System.Management.Automation.Language.Token[]]$tokens = $null
    [int]$cursor = 0
    [string]$commandName = ''
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$null, [ref]$tokens, [ref]$null, [ref]$cursor)
    foreach ($token in $tokens) {
        if ($token.Extent.StartOffset -gt $cursor) { break }
        if ($token.TokenFlags -band [System.Management.Automation.Language.TokenFlags]::CommandName) {
            $commandName = $token.Text
        }
    }
    if ($commandName) {
        # -ErrorAction Ignore has no effect
        try { $null = Get-Help $commandName -Online } catch {}
    }
}
