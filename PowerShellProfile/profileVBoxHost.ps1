# Copyright (c) 2023 Matthias Wolf, Mawosoft.

# VirtualBox aliases

if (Test-Path 'env:VBOX_MSI_INSTALL_PATH') {
    Set-Alias -Scope 'Global' -Name 'vbi' -Value (Join-Path $env:VBOX_MSI_INSTALL_PATH 'vbox-img.exe')
    Set-Alias -Scope 'Global' -Name 'vbm' -Value (Join-Path $env:VBOX_MSI_INSTALL_PATH 'VBoxManage.exe')
}
