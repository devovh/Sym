netsh dnsclient set encryption server=1.1.1.1 dohtemplate=https://cloudflare-dns.com/dns-query autoupgrade=yes udpfallback=no
netsh dnsclient set encryption server=1.0.0.1 dohtemplate=https://cloudflare-dns.com/dns-query autoupgrade=yes udpfallback=no
netsh dnsclient set global doh=yes
netsh dnsclient show encryption server=1.1.1.1
netsh dnsclient show encryption server=1.0.0.1
netsh dnsclient show global
pause