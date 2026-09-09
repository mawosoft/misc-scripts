# Copyright (c) Matthias Wolf, Mawosoft.

function CallingScriptSimpleFunc {
    CalleeInScript 'CallingScript SimpleFunc'
    CalleeInModule 'CallingScript SimpleFunc'
}

function CallingScriptCmdletFunc {
    [CmdletBinding()]
    param()
    CalleeInScript 'CallingScript CmdletFunc'
    CalleeInModule 'CallingScript CmdletFunc'
}

CallingScriptSimpleFunc
CallingScriptCmdletFunc
CalleeInScript 'Toplevel of CallingScript'
CalleeInModule 'Toplevel of CallingScript'
