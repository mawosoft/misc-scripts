# Copyright (c) Matthias Wolf, Mawosoft.

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
    $bfi = [System.Reflection.BindingFlags]'Instance, NonPublic'
    $piInternal = [System.Management.Automation.SessionState].GetProperty('Internal', $bfi)
    # $PSCmdlet.SessionState actually contains the session state of the caller, not the one
    # currently applying here.
    $callerState = $piInternal.GetValue($PSCmdlet.SessionState)
    $scope = $piInternal.PropertyType.GetProperty('CurrentScope', $bfi).GetValue($callerState)
    $moduleScope = $piInternal.PropertyType.GetProperty('ModuleScope', $bfi).GetValue($callerState)
    $tiScope = $scope.GetType()
    $piParent = $tiScope.GetProperty('Parent', $bfi)
    $piMode = $tiScope.GetProperty('StrictModeVersion', $bfi)
    # If we share SessionState with the caller, CurrentScope is our own scope.
    # But since we didn't change StrictMode, we don't need to adjust.
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
