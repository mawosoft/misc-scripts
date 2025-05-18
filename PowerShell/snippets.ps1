# Copyright (c) Matthias Wolf, Mawosoft.

<#
.SYNOPSIS
    Code snippets for Powershell.
.DESCRIPTION
    Defines code snippets for PowerShell and outputs them as a JSON string for use in
    a VSCode code snippets file.
.OUTPUTS
    [string] JSON string for use in a VSCode code snippets file.
.NOTES
    - The 'body' property can be a [scriptblock] to allow syntax checking.
    - However, when using template variables, 'body' must be a string.
      Using a single here-string is fine (no need for those silly line arrays).
.LINK
    https://code.visualstudio.com/docs/editor/userdefinedsnippets
#>

[CmdletBinding()]
[OutputType([string])]
param()

@{
    'no-dotsourcing'     = @{
        prefix      = 'no-dotsourcing'
        description = 'Prevent global dot-sourcing of a script.'
        body        = {
            try {
                $null = Get-Variable 'foobar' -Scope 1 -ErrorAction Stop
            }
            catch [System.ArgumentOutOfRangeException] {
                throw 'Dot-sourcing this script is not allowed.'
            }
            catch {}
        }
    }

    'dynamic-assemblies' = @{
        prefix      = 'dynamic-assemblies'
        description = 'Get the assemblies with dynamically created types.'
        body        = {
            [System.AppDomain]::CurrentDomain.GetAssemblies().Where({ $_.IsDynamic -or $_.GetName().Version -eq '0.0.0.0' })
        }
    }

    'dynamic-types'      = @{
        prefix      = 'dynamic-types'
        description = 'Get the dynamically created types and their assemblies.'
        body        = {
            [System.AppDomain]::CurrentDomain.GetAssemblies().Where({
                    $_.IsDynamic -or $_.GetName().Version -eq '0.0.0.0'
                }) | Select-Object FullName, ExportedTypes
        }
    }


} | ForEach-Object {
    $_.GetEnumerator().ForEach({
            if ($_.Value.body -is [scriptblock]) {
                $_.Value.body = ([string]$_.Value.body).Trim().Replace('$', '\$') -csplit '\r?\n'
            }
            else {
                $_.Value.body = ([string]$_.Value.body).Trim() -csplit '\r?\n'
            }
        })
    $_
} | ConvertTo-Json
