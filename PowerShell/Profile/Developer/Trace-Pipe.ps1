# Copyright (c) Matthias Wolf, Mawosoft.

<#
.SYNOPSIS
    Traces write operations to the output pipeline.
.DESCRIPTION
    The Trace-Pipe cmdlet traces write operations to the output pipeline. The trace includes pipe index,
    object type, and the script call stack. The information is written to the Debug stream.
    This allows for easily identifying accidentally leaked outputs to the pipe.
.INPUTS
    You can pipe anything to this cmdlet.
.OUTPUTS
    The cmdlet passes the input through unchanged.
.EXAMPLE
    Some-Script | Trace-Pipe
#>
function Trace-Pipe {
    [CmdletBinding(PositionalBinding = $false)]
    [Alias('trp')]
    param(
        # Accepts pipeline input.
        [Parameter(ValueFromPipeline)]
        [Object]$InputObject,

        # The depth of the call stack. The default is 1, showing the immediate caller.
        [int]$StackDepth = 1,

        # Only write trace information for null values in the pipe.
        [switch]$NullOnly,

        # Include the exact source position and the full path of the source file in the trace.
        # By default, the trace includes the line number and file name.
        [switch]$Detailed
    )
    begin {
        # Set $DebugPreference locally, because using -Debug switch on 5.1 sets preference to 'Inquire'.
        $DebugPreference = [System.Management.Automation.ActionPreference]::Continue
        [int]$pipeIndex = 0
    }
    process {
        if (-not $NullOnly -or $null -eq $InputObject) {
            [string]$type = '<null>'
            if ($null -ne $InputObject) { $type = $InputObject.GetType().ToString() }
            [string]$pipeText = "Pipe item $($pipeIndex): $type"
            [int]$stackIndex = -1
            foreach ($frame in [runspace]::DefaultRunspace.Debugger.GetCallStack()) {
                $stackIndex++
                if ($stackIndex -eq 0) { continue } # self
                if ($stackIndex -gt $StackDepth) { break }
                [string]$file = $frame.ScriptName
                if (-not $file) {
                    $file = '<no file>'
                }
                elseif (-not $Detailed) {
                    $file = [System.IO.Path]::GetFileName($file)
                }
                if ($Detailed) {
                    $p = $frame.Position
                    $frameText = ' at {0},{1}-{2},{3} {4} of {5}' -f @(
                        $p.StartLineNumber, $p.StartColumnNumber,
                        $p.EndLineNumber, $p.EndColumnNumber,
                        $frame.FunctionName, $file)
                }
                else {
                    $frameText = " at line $($frame.ScriptLineNumber) $($frame.FunctionName) of $file"
                }
                if ($stackIndex -eq 1) {
                    Write-Debug ($pipeText + $frameText)
                }
                else {
                    Write-Debug $frameText
                }
            }
            if ($stackIndex -lt 0) {
                Write-Debug "$pipeText at <no stack>"
            }
        }
        $pipeIndex++
        $InputObject
    }
}
