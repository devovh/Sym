@echo off
echo Registering libraries in System32...
for %%i in (%windir%\System32\*.ocx) do (
    echo Registration %%i
    regsvr32.exe /s "%%i"
)
for %%i in (%windir%\System32\*.dll) do (
    echo Registration %%i
    regsvr32.exe /s "%%i"
)
echo Done.
pause
