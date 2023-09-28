@echo off
rem Usage: Place VMSnapStartGuest into the autostart folder of the VM.

rem See corresponding VMSnapStartHost.

rem Basic VBoxControl command used
set vbgp=vboxcontrol --nologo guestproperty
rem Preset error msg for easier if/goto handling
set emsg=

%vbgp% get SnapStart
if errorlevel 1 goto warning

rem See bug description in VMSnapStartHost
set emsg=guestproperty unset command failed.
%vbgp% unset SnapStart
if errorlevel 1 goto failed
goto fini

:failed
echo.
echo ***ERROR*** %emsg%
echo.
pause
goto fini

:warning
echo.
echo ***WARNING***
echo.
echo The VM has not been started via script.
echo.
echo An automatic snapshot has not been taken!
echo.
pause
goto fini

:fini
