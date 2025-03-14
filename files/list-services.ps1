Get-CIMInstance -Class Win32_Service | Select-Object Name, DisplayName, Description, StartMode, DelayedAutoStart, StartName, PathName, State, ProcessId | Export-Clixml -Path C:\output-file.xml
pause