# 1. Usuń stare konfiguracje DoH Quad9 i Google
$remove = @(
    "9.9.9.9",
    "149.112.112.112",
    "2620:fe::9",
    "2620:fe::fe",
    "8.8.8.8",
    "8.8.4.4",
    "2001:4860:4860::8844",
    "2001:4860:4860::8888",
	"2606:4700:4700::1001",
	"2606:4700:4700::1111"
)

foreach ($dns in $remove) {
    netsh dns delete encryption server=$dns
}

# 2. Ustaw Cloudflare IPv4
netsh dns add encryption server=1.1.1.1 dohtemplate=https://cloudflare-dns.com/dns-query autoupgrade=yes udpfallback=no

netsh dns add encryption server=1.0.0.1 dohtemplate=https://cloudflare-dns.com/dns-query autoupgrade=yes udpfallback=no

# 3. Ustaw DNS tylko IPv4 na Ethernet
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses @("1.1.1.1","1.0.0.1")

# 4. Wyczyść cache
Clear-DnsClientCache
ipconfig /flushdns

# 5. Kontrola
Get-DnsClientServerAddress -InterfaceAlias "Ethernet"
Get-DnsClientDohServerAddress
pause