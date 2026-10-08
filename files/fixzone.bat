reg query "HKLM\Software\Policies\Microsoft\Windows\CurrentVersion\Internet Settings" /s
reg delete "HKLM\Software\Policies\Microsoft\Windows\CurrentVersion\Internet Settings" /v Security_zones_map_edit /f
reg delete "HKLM\Software\Policies\Microsoft\Windows\CurrentVersion\Internet Settings" /v Security_options_edit /f
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v LockDatabase /f
reg delete "HKLM\Software\Policies\Microsoft\Edge" /f
reg delete "HKLM\Software\Policies\Microsoft\Internet Explorer\Download" /v RunInvalidSignatures /f
reg delete "HKLM\Software\Policies\Microsoft\Internet Explorer\Download" /v CheckExeSignatures /f
gpupdate /force
pause


