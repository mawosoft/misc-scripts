# Copyright (c) Matthias Wolf, Mawosoft.

<#
.SYNOPSIS
    Gets the types defined in dynamic assemblies.
.OUTPUTS
    - String - The AssemblyQualifiedName of each type.
    - Type - The types itself if -PassThru is specified
#>
function Get-DynamicType {
    [CmdletBinding()]
    [Alias('gdt')]
    [OutputType([string], [type])]
    param(
        [switch]$PassThru
    )

    [System.AppDomain]::CurrentDomain.GetAssemblies().
    Where({ $_.IsDynamic -or $_.GetName().Version -eq '0.0.0.0' }).
    ForEach({ $_.DefinedTypes.ForEach({ if ($PassThru) { $_ } else { $_.AssemblyQualifiedName } }) })
}
