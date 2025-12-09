Write-Host "=== WINDOWS 11 SECURITY REPORT ===" -ForegroundColor Cyan

# --- TPM check ---
$tpm = Get-Tpm
if ($tpm.TpmPresent) {
    Write-Host "TPM present: Yes"
    Write-Host "TPM ready: $($tpm.TpmReady)"
    Write-Host "TPM version: $($tpm.TpmVersion)"
} else {
    Write-Host "TPM: Not available"
}

# --- Secure Boot check ---
try {
    $sb = Confirm-SecureBootUEFI
    if ($sb) { Write-Host "Secure Boot: Enabled" } else { Write-Host "Secure Boot: Disabled" }
} catch {
    Write-Host "Secure Boot: Not supported"
}

# --- Hypervisor / VBS / HVCI check (safe) ---
$hyper = (Get-ComputerInfo).HypervisorPresent
Write-Host "Hypervisor present: $hyper"
try {
    Get-CimClass -Namespace root\cimv2 -ClassName Win32_DeviceGuard -ErrorAction Stop | Out-Null
    $ci = Get-CimInstance -ClassName Win32_DeviceGuard
    Write-Host "Configured services: $($ci.SecurityServicesConfigured)"
    Write-Host "Running services: $($ci.SecurityServicesRunning)"
    Write-Host "VBS status: $($ci.VirtualizationBasedSecurityStatus)"
    if ($ci.SecurityServicesRunning -contains 1) {
        Write-Host "Memory Integrity (HVCI): Enabled"
    } else {
        Write-Host "Memory Integrity (HVCI): Disabled"
    }
} catch {
    Write-Host "DeviceGuard/VBS: Class not available (no data or not supported)"
}

# --- System Guard Secure Launch check (safe) ---
$sysGuardNs = 'root\Microsoft\Windows\SystemGuard'
try {
    Get-CimClass -Namespace $sysGuardNs -ClassName Win32_SystemGuardSecureLaunch -ErrorAction Stop | Out-Null
    $sg = Get-CimInstance -Namespace $sysGuardNs -ClassName Win32_SystemGuardSecureLaunch
    if ($sg -and $sg.SecureLaunchEnabled) {
        Write-Host "Secure Launch: Enabled"
    } else {
        Write-Host "Secure Launch: Disabled"
    }
} catch {
    Write-Host "Secure Launch: Namespace or class not available (likely not supported on this device/build)"
}

# --- BitLocker check ---
try {
    Get-BitLockerVolume | ForEach-Object {
        Write-Host "Drive $($_.MountPoint): $($_.ProtectionStatus)"
    }
} catch {
    Write-Host "BitLocker: No data"
}

# --- Windows Firewall check ---
Get-NetFirewallProfile | ForEach-Object {
    Write-Host "Profile $($_.Name): Enabled=$($_.Enabled)"
}
Write-Host "Active firewall rules: $((Get-NetFirewallRule | Where-Object {$_.Enabled -eq 'True'}).Count)"

# --- UAC check ---
$uac = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -ErrorAction SilentlyContinue
if ($uac.EnableLUA -eq 1) { Write-Host "UAC: Enabled" } else { Write-Host "UAC: Disabled" }

# --- LSA Protection check ---
$lsa = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "RunAsPPL" -ErrorAction SilentlyContinue
if ($lsa.RunAsPPL -eq 1 -or $lsa.RunAsPPL -eq 2) { Write-Host "LSA Protection: Enabled" } else { Write-Host "LSA Protection: Disabled" }

# --- Windows Sandbox check ---
$sandbox = Get-WindowsOptionalFeature -Online -FeatureName "Containers-DisposableClientVM"
Write-Host "Windows Sandbox: $($sandbox.State)"

# --- Smart App Control check ---
$sac = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy" -Name "VerifiedAndReputablePolicyState" -ErrorAction SilentlyContinue
if ($sac.VerifiedAndReputablePolicyState -eq 1) { Write-Host "Smart App Control: Enabled" } else { Write-Host "Smart App Control: Disabled or not supported" }

# --- RDP / NLA check ---
$rdpEnabled = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -ErrorAction SilentlyContinue
$nla = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -ErrorAction SilentlyContinue
if ($rdpEnabled.fDenyTSConnections -eq 0) { Write-Host "RDP: Enabled" } else { Write-Host "RDP: Disabled" }
if ($nla.UserAuthentication -eq 1) { Write-Host "NLA: Enabled" } else { Write-Host "NLA: Disabled" }

# --- SMB check ---
try {
    $smb = Get-SmbServerConfiguration
    Write-Host "SMB signing: $($smb.EnableSecuritySignature)"
    Write-Host "SMB encryption: $($smb.EncryptData)"
} catch {
    Write-Host "SMB: No data"
}

# --- System info ---
(Get-ComputerInfo | Select-Object OsName, OsVersion, OsBuildNumber, OsArchitecture, WindowsProductName) | Format-List

Write-Host "`n=== END OF REPORT ===" -ForegroundColor Cyan

pause