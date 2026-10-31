Write-Host "========== DNS SECURITY AUDIT ==========" -ForegroundColor Cyan

Write-Host "`n[1] DNS servers"
Get-DnsClientServerAddress

Write-Host "`n[2] DoH encryption"
netsh dnsclient show encryption

Write-Host "`n[3] Global encryption"
netsh dnsclient show global

Write-Host "`n[4] DNS Client service"
Get-Service Dnscache

Write-Host "`n[5] DNS cache count"
(Get-DnsClientCache).Count

Write-Host "`n[6] DNS client configuration"
Get-DnsClient |
Format-Table InterfaceAlias, ConnectionSpecificSuffix, RegisterThisConnectionsAddress, UseSuffixWhenRegistering

Write-Host "`n[7] DNS-related TCP connections"
Get-NetTCPConnection -State Established |
Where-Object RemotePort -eq 443 |
Select-Object -First 20 LocalAddress, RemoteAddress, RemotePort

Write-Host "`n[8] DNS port 53 listeners"
Get-NetUDPEndpoint |
Where-Object LocalPort -eq 53

Write-Host "`n========== AUDIT FINISHED ==========" -ForegroundColor Green
pause