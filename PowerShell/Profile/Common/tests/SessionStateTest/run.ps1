# Copyright (c) Matthias Wolf, Mawosoft.

& {
    $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
    $caught = $false
    try {
        $null = Get-Variable 'foobar' -Scope 2 -ErrorAction Stop
    }
    catch [System.ArgumentOutOfRangeException] {
        $caught = $true
    }
    catch {}
    if (-not $caught) {
        throw 'This script needs to be dot-sourced.'
    }
}
. "$PSScriptRoot/TestLogger.ps1"
[TestLogger]::Log.Clear()
. "$PSScriptRoot/CalleeScript.ps1"
Import-Module "$PSScriptRoot/CalleeModule.psm1" -Global -Force
. "$PSScriptRoot/CallingScript.ps1"
Import-Module "$PSScriptRoot/CallingModule.psm1" -Global -Force
[TestLogger]::Log
