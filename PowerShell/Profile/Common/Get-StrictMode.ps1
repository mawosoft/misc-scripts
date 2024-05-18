# Copyright (c) 2023-2024 Matthias Wolf, Mawosoft.

<#
.SYNOPSIS
    Gets the StrictMode version applying to the scope of the caller.
    This is a pendant to Set-StrictMode.
.OUTPUTS
    [version] object of the StrictMode. A value of 0.0 equals -Off, a value of $null indicates
    that Set-StrictMode has not be called at all within the caller's scope.
#>
function Get-StrictMode {
    [CmdletBinding()]
    [OutputType([version])]
    param ()
    $bflags = [System.Reflection.BindingFlags]'Instance, NonPublic'
    # $PSCmdlet.SessionState actually contains the session state of the caller, not the one
    # currently applying here.
    $state = [System.Management.Automation.SessionState].GetProperty('Internal', $bflags).GetValue($PSCmdlet.SessionState)
    [type]$stateType = $state.GetType()
    $scope = $stateType.GetProperty('CurrentScope', $bflags).GetValue($state)
    $moduleScope = $stateType.GetProperty('ModuleScope', $bflags).GetValue($state)
    [type]$scopeType = $scope.GetType()
    [System.Reflection.PropertyInfo]$piParent = $scopeType.GetProperty('Parent', $bflags)
    [System.Reflection.PropertyInfo]$piMode = $scopeType.GetProperty('StrictModeVersion', $bflags)
    while ($null -ne $scope) {
        [version]$mode = $piMode.GetValue($scope)
        if ($null -ne $mode) {
            return $mode
        }
        # Modules don't inherit strict mode from global scope.
        if ($scope -eq $moduleScope) { break }
        $scope = $piParent.GetValue($scope)
    }
    return $null
}
