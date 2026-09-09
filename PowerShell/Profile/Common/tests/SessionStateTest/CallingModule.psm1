# Copyright (c) Matthias Wolf, Mawosoft.

function CallingModuleSimpleFunc {
    CalleeInScript 'CallingModule SimpleFunc'
    CalleeInModule 'CallingModule SimpleFunc'
}

function CallingModuleCmdletFunc {
    [CmdletBinding()]
    param()
    CalleeInScript 'CallingModule CmdletFunc'
    CalleeInModule 'CallingModule CmdletFunc'
}

CallingModuleSimpleFunc
CallingModuleCmdletFunc
CalleeInScript 'Toplevel of CallingModule'
CalleeInModule 'Toplevel of CallingModule'
