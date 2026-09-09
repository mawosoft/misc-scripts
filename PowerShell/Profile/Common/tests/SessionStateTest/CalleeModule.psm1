# Copyright (c) Matthias Wolf, Mawosoft.

function CalleeInModule {
    [CmdletBinding()]
    param($caller)
    $stack = Get-PSCallStack
    [TestLogger]::LogCallee('CalleeInModule', $caller, $ExecutionContext, $PSCmdlet, $stack[1])
}

function PeerOfCalleeInModule {
    CalleeInModule 'Peer of CalleeInModule'
}

PeerOfCalleeInModule
CalleeInModule 'Toplevel of CalleeInModule'
