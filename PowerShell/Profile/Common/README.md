# Notes on Get-StrictMode

Caller scope vs. parent/child scopes.

```
[PSScriptCmdlet]        $PSCmdlet
[CommandOrigin]             .CommandOrigin                                 (Internal/Runspace)
[MshCommandRuntime]         .CommandRuntime                                (strictly ICommandRuntime)
[PipelineProcessor]             .PipelineProcessor
[SessionStateScope]                 .ExecutionScope         $7  (null)                      <-- Calling command scope
[SessionState]              .SessionState
[SessionStateInternal]          .Internal                                           $6
[SessionStateScope]                 .CurrentScope           $7  (null)                      <-- Calling command scope
[SessionState]              .InternalState
[SessionStateInternal]          .Internal                                           $6

[InvocationInfo]        $MyInvocation

[EngineIntrinsics]      $ExecutionContext
[SessionState]              .SessionState
[SessionStateInternal]          .Internal                                           $1
[SessionStateScope]                 .CurrentScope               $2  (4.0.1)
[SessionStateScope]                     .Parent                 $4
[SessionStateScope]                     .ScriptScope            $4
[Version]                               .StrictModeVersion
[ExecutionContext]                  .ExecutionContext                                   $5
[SessionStateScope]                 .GlobalScope                $3  (3.0)
[PSModuleInfo]                      .Module
[SessionStateScope]                 .ModuleScope                $4  (4.0)
[SessionStateScope]                 .ScriptScope                $4
[ExecutionContext]          ._context                                                   $5
[CommandProcessor]              CurrentCommandProcessor
[SessionStateScope]                 .CommandScope               $2
[SessionStateInternal]              .CommandSessionState                            $1
[ExecutionContext]                  .Context                                            $5
[bool]                              .UseLocalScope                 (true)
[SessionStateInternal]              ._previousCommandSessionState                   $6
[SessionStateScope]                     .CurrentScope           $7  (null)                  <-- Calling command scope
[SessionStateScope]                         .Parent                 (1.0)
[SessionStateScope]                 ._previousScope             $4                          <-- This is misleading and not the calling scope


[CallStackFrame[]]      Get-PSCallStack
[CallStackFrame]        [0]
[FunctionContext]           .FunctionContext
[ExecutionContext]              ._executionContext                                      $5
[ScriptBlock]                   ._scriptBlock
[SessionStateInternal]              .SessionStateInternal                           $1
[CallStackFrame]        [1]
[FunctionContext]           .FunctionContext
[ExecutionContext]              ._executionContext                                      $5
[ScriptBlock]                   ._scriptBlock
[SessionStateInternal]              .SessionStateInternal                           $6
[SessionStateScope]                     .CurrentScope           $7  (null)                  <-- Calling command scope
[CallStackFrame]        [2]
[FunctionContext]           .FunctionContext
[ExecutionContext]              ._executionContext                                      $5
[ScriptBlock]                   ._scriptBlock
[SessionStateInternal]              .SessionStateInternal                           (null, no state, global)
```

global
```powershell
Set-StrictMode -Version 3.0
Get-Mode1
```

StrictMode.psm1
```powershell
Set-StrictMode -Version 4.0
function Get-StrictMode {
    [CmdletBinding()]
    param()
    Set-StrictMode -Version 4.0.1
    [ExternalDebugView]::new().View(@(
            'PSCmdlet'
            $PSCmdlet
            'MyInvocation'
            $MyInvocation
            'ExecutionContext'
            $ExecutionContext
            'GetPSCallStack'
            Get-PSCallStack
    ))
}
```

Module1.psm1
```powershell
Set-StrictMode -Version 1.0
function Get-Mode1 {
    [CmdletBinding()]
    param()
    Get-StrictMode
}
function Get-Mode2 {
    [CmdletBinding()]
    param()
    Set-StrictMode -Version 1.0.2
    Get-StrictMode
}
```

Module2.psm1
```powershell
function Get-Mode3 {
    [CmdletBinding()]
    param()
    Get-StrictMode
}
function Get-Mode4 {
    [CmdletBinding()]
    param()
    Set-StrictMode -Version 4.0.4
    Get-StrictMode
}
```
