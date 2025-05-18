# Copyright (c) Matthias Wolf, Mawosoft.

<#
.SYNOPSIS
    Normalizes all objects in a collection to have identical sets of properties.
.OUTPUTS
    Objects, each with the same set of properties.
.NOTES
    Passing a collection through Expand-Object ensures that cmdlets like Export-Csv or Out-GridView
    won't miss any properties that only appear on objects further down the pipeline.
    By default, Expand-Object will flatten nested collections and convert dictionary-like objects
    into custom objects. This can be prevented by using the -NoDictionary and -NoFlatten parameters.
    Dictionary conversion: [pscustomobject]@{ foo = 'bar'; baz = 'buzz' }
    Note that if you don't also specify -NoFlatten, dictionaries will still be unrolled as key/value pairs:
    [pscustomobject]@{ Key = 'foo'; Value = 'bar' }, [pscustomobject]@{ Key = 'baz'; Value = 'buzz' }
#>
function Expand-Object {
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([psobject])]
    param(
        # The objects to process. It is recommended to use the pipeline for passing objects.
        [Parameter(ValueFromPipeline)]
        [psobject]$InputObject,
        # Prevents the conversion of dictionary-like objects (e.g. hashtable) into custom objects.
        [switch]$NoDictionary,
        # Prevents the flattening of nested collections.
        [switch]$NoFlatten
    )
    begin {

        class Processor {
            [System.Collections.Generic.List[psobject]]$Items
            [System.Collections.Generic.HashSet[string]]$PropertyNames
            [bool]$IsExpanded
            hidden [bool]$NoDictionary
            hidden [bool]$NoFlatten
            hidden [System.Collections.Generic.HashSet[string]]$CurrentPropertyNames

            Processor([bool] $noDictionary, [bool]$noFlatten) {
                $this.Items = [System.Collections.Generic.List[psobject]]::new()
                $this.PropertyNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
                $this.NoDictionary = $noDictionary
                $this.NoFlatten = $noFlatten
                $this.CurrentPropertyNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
            }

            [void]ProcessItems([psobject]$object) {
                if ($null -eq $object) { return }
                if (-not $this.NoDictionary -and $object -is [System.Collections.IDictionary]) {
                    $object = [pscustomobject][hashtable]$object
                    $this.IsExpanded = $true
                }
                if (-not $this.NoFlatten -and $object -is [System.Collections.ICollection]) {
                    foreach ($item in ([System.Collections.IEnumerable]$object).GetEnumerator()) {
                        $this.ProcessItems($item)
                    }
                }
                else {
                    if ($this.IsExpanded -or $this.PropertyNames.Count -eq 0) {
                        foreach ($property in $object.psobject.Properties) {
                            $this.PropertyNames.Add($property.Name)
                        }
                    }
                    else {
                        $this.CurrentPropertyNames.Clear()
                        foreach ($property in $object.psobject.Properties) {
                            $this.CurrentPropertyNames.Add($property.Name)
                        }
                        if (-not $this.PropertyNames.SetEquals($this.CurrentPropertyNames)) {
                            $this.IsExpanded = $true
                            $this.PropertyNames.UnionWith($this.CurrentPropertyNames)
                        }
                    }
                    $this.Items.Add($object)
                }
            }
            [System.Collections.ICollection]GetItems() {
                if (-not $this.IsExpanded) {
                    return $this.Items
                }
                [System.Collections.Generic.List[psobject]]$newItems = [System.Collections.Generic.List[psobject]]::new($this.Items.Count)
                foreach ($item in $this.Items) {
                    # PowerShell 5.1 compat: Not available: [psobject]::new($this.PropertyNames.Count)
                    [psobject]$newItem = [psobject]::new()
                    $this.CurrentPropertyNames.Clear()
                    foreach ($property in $item.psobject.Properties) {
                        $this.CurrentPropertyNames.Add($property.Name)
                        $newItem.psobject.Properties.Add([psnoteproperty]::new($property.Name, $property.Value))
                    }
                    foreach ($property in $this.PropertyNames) {
                        if (-not $this.CurrentPropertyNames.Contains($property)) {
                            $newItem.psobject.Properties.Add([psnoteproperty]::new($property, $null))
                        }
                    }
                    $newItems.Add($newItem)
                }
                return $newItems
            }
        }

        [Processor]$processor = [Processor]::new($NoDictionary, $NoFlatten)
    }
    process {
        $processor.ProcessItems($InputObject)
    }
    end {
        $PSCmdlet.WriteObject($processor.GetItems(), $true)
    }
}
