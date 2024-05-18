# Copyright (c) 2023-2024 Matthias Wolf, Mawosoft.

<#
.SYNOPSIS
    Adds the [ExternalDebugView] class.
.DESCRIPTION
    The [ExternalDebugView] class breaks into or launches an external debugger for managed code.
    Methods:
        public void View(object @object);
    Properties:
        public static bool DisabledGlobally;
        public bool Disabled;
.NOTES
    This is wrapped into a function, because using Add-Type -TypeDefinition <sourcecode> is relatively
    time-consuming and the feature itself will be used infrequently.
#>
function Add-ExternalDebugView {
    [CmdletBinding()]
    param()
    Add-Type -TypeDefinition @'
        using System.Diagnostics;

        public sealed class ExternalDebugView
        {
            private static volatile bool s_disabledGlobally;

            public static bool DisabledGlobally
            {
                // Verbose form for Windows PowerShell
                get
                {
                    return s_disabledGlobally;
                }
                set
                {
                    s_disabledGlobally = value;
                }
            }

            public bool Disabled { get; set; }

            // The argument passed to View() is not always accessible in the Debugger.
            // We temporarly store it here to work around that issue.
            public object Object { get; set; }

            public void View(object @object)
            {
                if (Disabled || DisabledGlobally) return;
                Object = @object;
                if (Debugger.IsAttached)
                {
                    Debugger.Break();
                }
                else
                {
                    Debugger.Launch();
                }
                Object = null;
            }
        }
'@
}
