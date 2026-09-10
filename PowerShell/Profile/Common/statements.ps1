# Copyright (c) Matthias Wolf, Mawosoft.

Set-StrictMode -Version 3
$ErrorActionPreference = 'Stop'

# Disable AMSI method invocation logging.
# We must do this at the earliest point to avoid compiled scripts referring the original method.
# Note that this doesn't fully get rid of AMSI logging, but it mitigates against the worst
# offender with regards to security and performance.
& {
    if ($PSVersionTable.PSVersion -lt '7.3') { return }
    $fi = [psobject].Assembly.GetType('System.Management.Automation.Language.CachedReflectionInfo').GetField('MemberInvocationLoggingOps_LogMemberInvocation', [System.Reflection.BindingFlags]'NonPublic, Static')
    if ($null -eq $fi) {
        Write-Host '**DeAmsify** Field not found: MemberInvocationLoggingOps_LogMemberInvocation'
        return
    }
    $mi = $fi.GetValue($null)
    if ($mi -is [System.Reflection.Emit.DynamicMethod]) {
        Write-Host '**DeAmsify** Already dynamic: MemberInvocationLoggingOps_LogMemberInvocation'
        return
    }
    if ($mi -isnot [System.Reflection.MethodInfo] -or $mi.ReturnType -ne [void]) {
        Write-Host '**DeAmsify** Invalid MethodInfo: MemberInvocationLoggingOps_LogMemberInvocation'
        return
    }
    $paramTypes = [type[]] ($mi.GetParameters() | Select-Object -ExpandProperty ParameterType)
    $dmReplacement = [System.Reflection.Emit.DynamicMethod]::new('', $null, $paramTypes, $true)
    $dmReplacement.GetILGenerator().Emit([System.Reflection.Emit.OpCodes]::Ret)
    # Target field is readonly, use DynamicMethod to bypass.
    $dmSetter = [System.Reflection.Emit.DynamicMethod]::new('', $null, [type[]]@([System.Object]), $true)
    $il = $dmSetter.GetILGenerator()
    $il.Emit([System.Reflection.Emit.OpCodes]::Ldarg_0)
    $il.Emit([System.Reflection.Emit.OpCodes]::Stsfld, $fi)
    $il.Emit([System.Reflection.Emit.OpCodes]::Ret)
    $dmSetter.Invoke($null, @(, $dmReplacement))
}

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

# Additional PowerShell aliases
New-Alias -Name 'cfj' -Value 'ConvertFrom-Json'
New-Alias -Name 'ctj' -Value 'ConvertTo-Json'
New-Alias -Name 'os' -Value 'Out-String'
