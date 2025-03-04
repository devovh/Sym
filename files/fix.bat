sfc /scannow
dism /online /cleanup-image /restorehealth
dism /online /cleanup-image /startcomponentcleanup
chkdsk
chkdsk /scan /forceofflinefix
pause