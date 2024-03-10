sc stop msrpc
sc config msrpc start=disabled
sc stop Dnscache
sc config Dnscache start=disabled
sc stop WinRM
sc config WinRM start=disabled
sc stop upnphost
sc config upnphost start=disabled
sc stop UmRdpService
sc config UmRdpService start=disabled
sc stop uhssvc
sc config uhssvc start=disabled
sc stop UevAgentService
sc config UevAgentService start=disabled
sc stop ssh-agent
sc config ssh-agent start=disabled
sc stop SSDPSRV
sc config SSDPSRV start=disabled
sc stop RtkBtManServ
sc config RtkBtManServ start=disabled
sc stop RmSvc
sc config RmSvc start=disabled
sc stop RemoteRegistry
sc config RemoteRegistry start=disabled
sc stop RemoteAccess
sc config RemoteAccess start=disabled
sc stop LanmanServer
sc config LanmanServer start=disabled
sc stop shpamsvc
sc config shpamsvc start=disabled
sc stop LanmanWorkstation
sc config LanmanWorkstation start=disabled
sc stop lfsvc
sc config lfsvc start=disabled
sc stop CDPSvc
sc config CDPSvc start=disabled
sc stop SstpSvc
sc config SstpSvc start=disabled
sc stop DsSvc
sc config DsSvc start=disabled
sc stop WMPNetworkSvc
sc config WMPNetworkSvc start=disabled
sc stop AppVClient
sc config AppVClient start=disabled
sc stop jhi_service
sc config jhi_service start=disabled
sc stop HfcDisableService
sc config HfcDisableService start=disabled
sc stop iphlpsvc
sc config iphlpsvc start=disabled
sc stop lmhosts
sc config lmhosts start=disabled
sc stop YMC
sc config YMC start=disabled
sc stop MySQL80
sc config MySQL80 start=disabled
sc stop ImControllerService
sc config ImControllerService start=disabled
sc stop AESMService
sc config AESMService start=disabled
sc stop LITSSVC
sc config LITSSVC start=disabled
sc stop clamd
sc config clamd start=disabled
sc start SNMPTRAP
sc config SNMPTRAP start=auto
sc start SharedAccess
sc config SharedAccess start=auto
sc stop GigabyteUpdateService
sc config GigabyteUpdateService start=disabled
sc delete GigabyteUpdateService
sc stop WpnService
sc config WpnService start=disabled
sc stop DsmSvc
sc config DsmSvc start=disabled
sc stop KeyIso
sc config KeyIso start=disabled
sc stop SamSs
sc config SamSs start=disabled
sc start VaultSvc
sc config VaultSvc start=auto
sc stop DiagTrack
sc config DiagTrack start=disabled
sc stop wlidsvc
sc config wlidsvc start=disabled
pause