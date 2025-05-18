# Copyright (c) Matthias Wolf, Mawosoft.

<#
.SYNOPSIS
    Imports the VsDevCmd environment variables
#>
function Import-VsDevCmd {
    [CmdletBinding()]
    [Alias('ipvsd')]
    param()
    Import-BatchEnvironment (Get-Alias 'vsdevcmd').Definition
}
