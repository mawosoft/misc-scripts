# Copyright (c) 2023 Matthias Wolf, Mawosoft.

<#
.SYNOPSIS
    Lists all Powershell profiles and tests if they exist.
.OUTPUTS
    [PSObject[]] with profile infos
#>
function global:Get-Profile {
    [CmdletBinding()]
    [OutputType([psobject[]])]
    param()

    foreach ($scope in ('AllUsersAllHosts', 'AllUsersCurrentHost', 'CurrentUserAllHosts', 'CurrentUserCurrentHost')) {
        [pscustomobject]@{
            Scope  = $scope
            Path   = $PROFILE.$($scope)
            Exists = Test-Path -Path $PROFILE.$($scope) -PathType Leaf
        }
    }
}

<#
.SYNOPSIS
    # Invokes a batch file (.bat, .cmd) and imports the environment variables it has set.
.NOTES
    TODO
    - proper use of %comspec% or cmd definition
    - preserve working dir, psmodulepath
    - Batch parameters and other goodies
#>
function global:Import-BatchEnvironment {
    param (
        # The batch file to run
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    [string]$tempfile = New-TemporaryFile
    cmd /c " ""$Path"" && set >""$tempfile"" "
    Get-Content $tempfile | ForEach-Object {
        [int]$i = $_.IndexOf('=', [System.StringComparison]::Ordinal)
        if ($i -gt 0) {
            Set-Content "env:$($_.Substring(0, $i))" $_.Substring($i + 1)
        }
    }

    Remove-Item $tempfile -ErrorAction Ignore
}
