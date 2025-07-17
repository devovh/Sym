netsh int tcp set global autotuninglevel=normal
netsh int tcp set global rss=enabled
netsh int tcp set supplemental template=internet congestionprovider=ctcp
netsh int tcp set global ecncapability=disabled
netsh int tcp set global timestamps=disabled
Pause