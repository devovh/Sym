# Automatic disabling of administrative shares
# Depending on the system type, sets AutoShareServer or AutoShareWks

$path = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"

# Retrieving the system type
$edition = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").InstallationType

if ($edition -eq "Server") {
    Write-Host "Detected Windows Server – setting AutoShareServer = 0"
    Set-ItemProperty -Path $path -Name AutoShareServer -Value 0 -Type DWord
}
else {
    Write-Host "Detected Windows Workstation – setting AutoShareWks = 0"
    Set-ItemProperty -Path $path -Name AutoShareWks -Value 0 -Type DWord
}

# Restarting the Server service
Restart-Service -Name LanmanServer -Force

Write-Host "Administrative shares have been disabled."
pause