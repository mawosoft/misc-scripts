# Copyright (c) Matthias Wolf, Mawosoft.

function CalleeInScript {
    [CmdletBinding()]
    param($caller)
    $stack = Get-PSCallStack
    [TestLogger]::LogCallee('CalleeInScript', $caller, $ExecutionContext, $PSCmdlet, $stack[1])
}

function PeerOfCalleeInScript {
    CalleeInScript 'Peer of CalleeInScript'
}

PeerOfCalleeInScript
CalleeInScript 'Toplevel of CalleeInScript'
