# Sprawdzenie podstawowych zabezpieczeń systemu Windows Server 2022
Write-Host "=== AUDYT BEZPIECZEŃSTWA WINDOWS SERVER 2022 ===" -ForegroundColor Cyan

# 1. Secure Boot
$secureBoot = Confirm-SecureBootUEFI
Write-Host "Secure Boot: $secureBoot"

# 2. Virtualization Based Security (VBS)
$vbs = Get-CimInstance -ClassName Win32_DeviceGuard
Write-Host "VBS Włączone: $($vbs.VirtualizationBasedSecurityStatus -eq 2)"

# 3. Credential Guard
Write-Host "Credential Guard: $($vbs.SecurityServicesRunning -contains 1)"

# 4. Windows Update status
$wu = Get-Service -Name wuauserv
Write-Host "Windows Update: $($wu.Status)"

# 5. Zapora (firewall)
$fw = Get-NetFirewallProfile
foreach ($profile in $fw) {
    Write-Host "$($profile.Name) Firewall: $($profile.Enabled)"
}

# 6. RDP zabezpieczenia
$rdpNLA = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name UserAuthentication
Write-Host "RDP z NLA: $($rdpNLA.UserAuthentication -eq 1)"

# 7. Silne hasła
$pwdPolicy = net accounts
Write-Host "`nPolityka haseł:"
$pwdPolicy

# 8. Sprawdzenie Bitdefender GravityZone (czy działa agent)
$bdService = Get-Service -Name "bdservicehost" -ErrorAction SilentlyContinue
if ($bdService) {
    Write-Host "Bitdefender GravityZone Agent: $($bdService.Status)"
} else {
    Write-Host "Bitdefender GravityZone Agent: NIE ZNALEZIONO" -ForegroundColor Red
}

Write-Host "`nAUDYT ZAKOŃCZONY" -ForegroundColor Green
pause