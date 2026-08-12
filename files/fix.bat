sfc /scannow
dism /online /cleanup-image /checkhealth
dism /online /cleanup-image /scanhealth
dism /online /cleanup-image /startcomponentcleanup
dism /online /cleanup-image /startcomponentcleanup /resetbase
dism /online /cleanup-image /restorehealth
chkdsk
chkdsk /scan /forceofflinefix
pause