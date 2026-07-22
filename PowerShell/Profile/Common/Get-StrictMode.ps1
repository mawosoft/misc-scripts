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
    $callerFrame = $null
    $e = ([System.Collections.IEnumerable][runspace]::DefaultRunspace.Debugger.GetCallStack()).GetEnumerator()
    if ($e.MoveNext() -and $e.MoveNext()) {
        $callerFrame = $e.Current
    }
    $edisp = $e -as [System.IDisposable]
    if ($null -ne $edisp) { $edisp.Dispose() }
    if ($null -eq $callerFrame) {
        return # Should not happen
    }
    $bfi = [System.Reflection.BindingFlags]'Instance, NonPublic'
    $piInternal = [System.Management.Automation.SessionState].GetProperty('Internal', $bfi)
    $thisState = $piInternal.GetValue($ExecutionContext.SessionState)
    $callerFunctionContext = [System.Management.Automation.CallStackFrame].GetProperty(
        'FunctionContext', $bfi).GetValue($callerFrame)
    # The real SessionState of the caller is only available via
    #   CallStackFrame.FunctionContext._scriptBlock.SessionState
    $callerState = $piInternal.GetValue([scriptblock].GetProperty('SessionState', $bfi).GetValue(
            $callerFunctionContext.GetType().GetField('_scriptBlock', $bfi).GetValue($callerFunctionContext)))
    $scope = $piInternal.PropertyType.GetProperty('CurrentScope', $bfi).GetValue($callerState)
    $moduleScope = $piInternal.PropertyType.GetProperty('ModuleScope', $bfi).GetValue($callerState)
    $tiScope = $scope.GetType()
    $piParent = $tiScope.GetProperty('Parent', $bfi)
    $piMode = $tiScope.GetProperty('StrictModeVersion', $bfi)
    if ($callerState -eq $thisState) {
        # Adjust scope if we share SessionState with caller
        $scope = $piParent.GetValue($scope)
    }
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
