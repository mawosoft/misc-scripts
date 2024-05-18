# Copyright (c) 2023-2024 Matthias Wolf, Mawosoft.

<#
.SYNOPSIS
    Lists all Powershell profile paths and if they exist.
.OUTPUTS
    Objects with profile infos
#>
function Get-Profile {
    [CmdletBinding()]
    [Alias('gpr')]
    [OutputType([psobject])]
    param()

    foreach ($scope in ('AllUsersAllHosts', 'AllUsersCurrentHost', 'CurrentUserAllHosts', 'CurrentUserCurrentHost')) {
        [pscustomobject]@{
            Scope  = $scope
            Path   = $PROFILE.$($scope)
            Exists = Test-Path -Path $PROFILE.$($scope) -PathType Leaf
        }
    }
}
