# Copyright (c) 2023 Matthias Wolf, Mawosoft.

Set-StrictMode -Version 3
$ErrorActionPreference = 'Stop'

# One history across all hosts per user
Set-PSReadLineOption -HistorySavePath (Join-Path (
        [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::MyDocuments)
    ) 'PowerShell\PSReadLine\AllHosts_history.txt' )
# Can be toggled with F2.
Set-PSReadLineOption -PredictionViewStyle ListView
