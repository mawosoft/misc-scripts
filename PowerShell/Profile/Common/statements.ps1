# Copyright (c) 2023-2024 Matthias Wolf, Mawosoft.

Set-StrictMode -Version 3
$ErrorActionPreference = 'Stop'

# One history across all hosts per user
Set-PSReadLineOption -HistorySavePath (Join-Path (
        [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::MyDocuments)
    ) 'PowerShell\PSReadLine\AllHosts_history.txt' )
# Can be toggled with F2.
Set-PSReadLineOption -PredictionViewStyle ListView

Set-PSReadLineKeyHandler -Chord Ctrl+Insert -Function Copy
Remove-PSReadLineKeyHandler -Chord 'Ctrl+]' # Impossible chord on German keyboard
Set-PSReadLineKeyHandler -Chord 'Ctrl+)' -Function GotoBrace

# Unified scrolling in stand-alone and VSCode terminal
# See corresponding bindings in file:///./vscode-keybindings.jsonc
Set-PSReadLineKeyHandler -Chord Ctrl+PageUp -Function ScrollDisplayUp
Set-PSReadLineKeyHandler -Chord Ctrl+PageDown -Function ScrollDisplayDown
Set-PSReadLineKeyHandler -Chord Ctrl+UpArrow -Function ScrollDisplayUpLine
Set-PSReadLineKeyHandler -Chord Ctrl+DownArrow -Function ScrollDisplayDownLine
Set-PSReadLineKeyHandler -Chord Ctrl+Home -Function ScrollDisplayTop
Set-PSReadLineKeyHandler -Chord Ctrl+End -Function ScrollDisplayToCursor

if ($env:TERM_PROGRAM -eq 'vscode' <#-and $env:VSCODE_NONCE#>) {
    # $env:TERM_PROGRAM is defined for toplevel and sub shells.
    # $env:VSCODE_NONCE is only defined for toplevel shell. It gets removed by the shell integration
    # script, which is only run in the toplevel shell, *not* in sub shells.
    # We could mitigate by running that script ourselves in a sub shell, but don't really see
    # a use case yet.
    # See corresponding bindings in file:///./vscode-keybindings.jsonc
    Set-PSReadLineKeyHandler -Chord 'F12,m' -Function (Get-PSReadLineKeyHandler -Chord Ctrl+Enter).Function
    Set-PSReadLineKeyHandler -Chord 'F12,n' -Function (Get-PSReadLineKeyHandler -Chord Shift+Ctrl+Enter).Function
    Set-PSReadLineKeyHandler -Chord 'F12,o' -Function (Get-PSReadLineKeyHandler -Chord Ctrl+C).Function
    Set-PSReadLineKeyHandler -Chord 'F12,p' -Function (Get-PSReadLineKeyHandler -Chord 'Ctrl+)').Function
    Set-PSReadLineKeyHandler -Chord 'F12,q' -Function (Get-PSReadLineKeyHandler -Chord 'Alt+?').Function
}

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
