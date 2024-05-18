# Copyright (c) 2023-2024 Matthias Wolf, Mawosoft.

# VirtualBox aliases

New-Alias -Name 'vbi' -Value (Join-Path $env:VBOX_MSI_INSTALL_PATH 'vbox-img.exe')
New-Alias -Name 'vbm' -Value (Join-Path $env:VBOX_MSI_INSTALL_PATH 'VBoxManage.exe')
