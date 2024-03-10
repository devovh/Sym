sfc /scannow
dism /online /cleanup-image /restorehealth
dism /online /cleanup-image /startcomponentcleanup
chkdsk /scan /forceofflinefix
pause