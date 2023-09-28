@echo off

rem Usage: VMSnapStartHost <vm uuid>

rem - Takes a snapshot of the powered off VM to mitigate crashes.
rem - Unplugs the network cable on adapter 1 for security.
rem - Starts the VM.
rem - Sets the transient guest property SnapStart=1.

rem VirtualBox v6.1.16
rem An autostart guest script (see VMSnapStartGuest) can query the property
rem via VBoxControl and alert the user if it's missing.
rem *BUG* Transient properties should be automatically deleted when the VM
rem shuts down, but somehow that doesn't happen. Therefore the guest script
rem should explicitly unset it (Only VBoxControl...unset seems to work, even
rem VBoxControl...delete has the variable somehow comming back).

rem VirtualBox v6.1.18
rem It seems, the property now survives a restart of the guest OS.
rem The property is removed on VM shutdown. Still using "unset". Not yet tested
rem if "delete" would work now.
rem Seems to have been a glitch, gone again after restart.


rem Unlike other path vars, this one already has trailing backslash.
set vbm="%VBOX_MSI_INSTALL_PATH%vboxmanage.exe" --nologo

rem Preset error msg for easier if/goto handling
set emsg=Missing VM uuid parameter.
if "%1" == "" goto failed

set emsg=The VM is not powered off.
%vbm% showvminfo %1 | find "State:" | find "powered off"
if errorlevel 1 goto failed

set emsg=snapshot command failed.
%vbm% snapshot %1 take "Starting VM"
if errorlevel 1 goto failed

set emsg=modifyvm command failed.
%vbm% modifyvm %1 --cableconnected1 off
if errorlevel 1 goto failed

set emsg=startvm command failed.
%vbm% startvm %1
if errorlevel 1 goto failed

set emsg=guestproperty command failed.
%vbm% guestproperty set %1 SnapStart 1 --flags TRANSIENT
if errorlevel 1 goto failed
goto fini

:failed
echo.
echo ***ERROR*** while starting the VM!
echo.
echo %emsg%
echo.
pause
goto fini

:fini
