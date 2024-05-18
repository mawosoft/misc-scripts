# Copyright (c) 2023-2024 Matthias Wolf, Mawosoft.

<#
.SYNOPSIS
    # Invokes a batch file (.bat, .cmd) and imports the environment variables it has set.
.NOTES
    TODO
    - proper use of %comspec% or cmd definition
    - preserve working dir, psmodulepath
    - Batch parameters and other goodies
#>
function Import-BatchEnvironment {
    [CmdletBinding()]
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
