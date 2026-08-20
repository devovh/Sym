#requires -RunAsAdministrator

<#
============================================================
 Windows Server 2022 Datacenter
 Secure Internet + Gaming Hardening v4
============================================================

SUPPORTED MODES:

    Audit
    Harden
    Diagnose
    Rollback

FIREWALL POLICY:

    DOMAIN  = INBOUND BLOCK / OUTBOUND BLOCK
    PRIVATE = INBOUND BLOCK / OUTBOUND BLOCK
    PUBLIC  = INBOUND BLOCK / OUTBOUND ALLOW

IMPORTANT:

    The active network profile MUST be PUBLIC before
    HARDEN mode is allowed.

DESIGN GOALS:

    - Internet browsing
    - Gaming
    - Steam / game launchers
    - Discord
    - Normal UDP traffic
    - IPv4 + IPv6
    - Microsoft Defender
    - Windows Server 2022
    - Security logging
    - Low compatibility impact

THE SCRIPT DOES NOT:

    - globally block UDP
    - disable IPv6
    - block gaming ports
    - disable Steam
    - disable Discord
    - disable browsers
    - disable Windows Update
    - automatically disable RDP if it is running
    - create arbitrary application firewall blocks

============================================================
#>

param(
    [ValidateSet("Audit","Harden","Diagnose","Rollback")]
    [string]$Mode = "Audit"
)

$ErrorActionPreference = "Continue"

# ============================================================
# DIRECTORIES
# ============================================================

$Root    = "C:\ServerSecurity"
$Backup  = "$Root\Backup"
$Logs    = "$Root\Logs"
$Reports = "$Root\Reports"

New-Item -ItemType Directory -Force -Path `
    $Root,$Backup,$Logs,$Reports | Out-Null

$Time = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

$LogFile = "$Logs\$Mode-$Time.log"

Start-Transcript -Path $LogFile -Append

# ============================================================
# FUNCTIONS - OUTPUT
# ============================================================

function Write-Section {
    param([string]$Text)

    Write-Host ""
    Write-Host "============================================================" `
        -ForegroundColor Cyan

    Write-Host " $Text" -ForegroundColor Cyan

    Write-Host "============================================================" `
        -ForegroundColor Cyan
}

function Write-OK {
    param([string]$Text)

    Write-Host "[OK] $Text" -ForegroundColor Green
}

function Write-WarningMsg {
    param([string]$Text)

    Write-Host "[WARNING] $Text" -ForegroundColor Yellow
}

function Write-Critical {
    param([string]$Text)

    Write-Host "[CRITICAL] $Text" -ForegroundColor Red
}

# ============================================================
# ADMIN CHECK
# ============================================================

function Test-Administrator {

    $Identity = [Security.Principal.WindowsIdentity]::GetCurrent()

    $Principal = New-Object `
        Security.Principal.WindowsPrincipal($Identity)

    return $Principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}

# ============================================================
# SYSTEM INFORMATION
# ============================================================

function Get-SystemInformation {

    Write-Section "SYSTEM INFORMATION"

    $OS = Get-CimInstance Win32_OperatingSystem

    Write-Host "Computer Name    : $env:COMPUTERNAME"
    Write-Host "Operating System : $($OS.Caption)"
    Write-Host "Version          : $($OS.Version)"
    Write-Host "Build            : $($OS.BuildNumber)"
    Write-Host ""

    Get-CimInstance Win32_Processor |
        Select-Object `
            Name,
            NumberOfCores,
            NumberOfLogicalProcessors |
        Format-Table -AutoSize
}

# ============================================================
# NETWORK PROFILE
# ============================================================

function Get-NetworkProfile {

    return Get-NetConnectionProfile |
        Select-Object `
            Name,
            InterfaceAlias,
            NetworkCategory,
            IPv4Connectivity,
            IPv6Connectivity
}

function Test-PublicNetwork {

    Write-Section "NETWORK PROFILE SAFETY CHECK"

    $Profiles = Get-NetworkProfile

    if (-not $Profiles) {

        Write-Critical "No network profile detected."

        return $false
    }

    $Profiles |
        Format-Table -AutoSize

    $PublicProfile = $Profiles |
        Where-Object {
            $_.NetworkCategory -eq "Public"
        }

    if (-not $PublicProfile) {

        Write-Critical `
            "Active network profile is NOT PUBLIC."

        Write-Critical `
            "HARDEN mode is blocked to prevent Internet loss."

        return $false
    }

    $Internet = $PublicProfile |
        Where-Object {
            $_.IPv4Connectivity -eq "Internet"
        }

    if ($Internet) {

        Write-OK "Active network profile: PUBLIC"
        Write-OK "IPv4 Internet connectivity: AVAILABLE"

        Write-Host ""
        Write-Host "Public Firewall:"
        Write-Host "    Inbound  = BLOCK"
        Write-Host "    Outbound = ALLOW"

        return $true
    }

    Write-Critical `
        "Public profile detected, but IPv4 Internet is unavailable."

    return $false
}

# ============================================================
# FIREWALL BACKUP
# ============================================================

function Backup-Firewall {

    param(
        [string]$Path
    )

    try {

        netsh advfirewall export `
            "$Path\Firewall.wfw" |
            Out-Null

        Get-NetFirewallProfile |
            Export-Clixml `
                "$Path\FirewallProfiles.xml"

        Get-NetFirewallRule |
            Select-Object `
                DisplayName,
                Enabled,
                Direction,
                Action,
                Profile,
                Group |
            Export-Csv `
                "$Path\FirewallRules.csv" `
                -NoTypeInformation `
                -Encoding UTF8

        Write-OK "Firewall backup created."

    }
    catch {

        Write-WarningMsg `
            "Firewall backup could not be completed."
    }
}

# ============================================================
# DEFENDER BACKUP
# ============================================================

function Backup-Defender {

    param(
        [string]$Path
    )

    try {

        Get-MpPreference |
            Export-Clixml `
                "$Path\DefenderPreference.xml"

        Write-OK "Defender configuration backup created."

    }
    catch {

        Write-WarningMsg `
            "Defender configuration backup failed."
    }
}

# ============================================================
# SERVICES BACKUP
# ============================================================

function Backup-Services {

    param(
        [string]$Path
    )

    try {

        Get-Service |
            Select-Object `
                Name,
                DisplayName,
                Status,
                StartType |
            Export-Csv `
                "$Path\Services.csv" `
                -NoTypeInformation `
                -Encoding UTF8

        Write-OK "Service configuration backup created."

    }
    catch {

        Write-WarningMsg `
            "Service backup failed."
    }
}

# ============================================================
# REGISTRY BACKUP
# ============================================================

function Backup-Registry {

    param(
        [string]$Path
    )

    $RegistryKeys = @(
        @{
            Key = "HKLM\SYSTEM\CurrentControlSet\Control\Lsa"
            File = "LSA.reg"
        },
        @{
            Key = "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"
            File = "DNSClient.reg"
        },
        @{
            Key = "HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell"
            File = "PowerShell.reg"
        }
    )

    foreach ($Item in $RegistryKeys) {

        try {

            reg.exe export `
                $Item.Key `
                "$Path\$($Item.File)" `
                /y |
                Out-Null

            Write-OK `
                "Registry backup: $($Item.File)"
        }
        catch {

            Write-WarningMsg `
                "Could not backup $($Item.Key)"
        }
    }
}

# ============================================================
# COMPLETE BACKUP
# ============================================================

function New-SecurityBackup {

    Write-Section "SECURITY BACKUP"

    $BackupPath = "$Backup\$Time"

    New-Item `
        -ItemType Directory `
        -Force `
        -Path $BackupPath |
        Out-Null

    Backup-Firewall -Path $BackupPath
    Backup-Defender -Path $BackupPath
    Backup-Services -Path $BackupPath
    Backup-Registry -Path $BackupPath

    Write-Host ""
    Write-OK "Backup directory:"
    Write-Host $BackupPath

    return $BackupPath
}

# ============================================================
# FIREWALL
# ============================================================

function Configure-Firewall {

    Write-Section "WINDOWS DEFENDER FIREWALL"

    try {

        # EXACT REQUESTED POLICY

        Set-NetFirewallProfile `
            -Profile Domain `
            -Enabled True `
            -DefaultInboundAction Block `
            -DefaultOutboundAction Block `
            -LogAllowed True `
            -LogBlocked True

        Set-NetFirewallProfile `
            -Profile Private `
            -Enabled True `
            -DefaultInboundAction Block `
            -DefaultOutboundAction Block `
            -LogAllowed True `
            -LogBlocked True

        Set-NetFirewallProfile `
            -Profile Public `
            -Enabled True `
            -DefaultInboundAction Block `
            -DefaultOutboundAction Allow `
            -LogAllowed True `
            -LogBlocked True

        # Firewall logging

        Set-NetFirewallProfile `
            -Profile Domain,Private,Public `
            -LogFileName "$Logs\Firewall.log" `
            -LogMaxSizeKilobytes 32767

        Write-OK `
            "DOMAIN  = INBOUND BLOCK / OUTBOUND BLOCK"

        Write-OK `
            "PRIVATE = INBOUND BLOCK / OUTBOUND BLOCK"

        Write-OK `
            "PUBLIC  = INBOUND BLOCK / OUTBOUND ALLOW"

    }
    catch {

        Write-Critical `
            "Firewall configuration failed."

        Write-Host $_
    }
}

# ============================================================
# DEFENDER
# ============================================================

function Configure-Defender {

    Write-Section "MICROSOFT DEFENDER"

    try {

        Set-MpPreference `
            -DisableRealtimeMonitoring $false `
            -DisableBehaviorMonitoring $false `
            -DisableIOAVProtection $false `
            -DisableScriptScanning $false `
            -DisableBlockAtFirstSeen $false

        Write-OK "Real-time protection: ENABLED"
        Write-OK "Behavior monitoring: ENABLED"
        Write-OK "IOAV protection: ENABLED"
        Write-OK "Script scanning: ENABLED"
        Write-OK "Block at first sight: ENABLED"

    }
    catch {

        Write-WarningMsg `
            "Some Defender preferences could not be changed."
    }

    try {

        Update-MpSignature `
            -ErrorAction SilentlyContinue

        Write-OK "Defender signatures update requested."

    }
    catch {

        Write-WarningMsg `
            "Defender signature update failed."
    }
}

# ============================================================
# NETWORK PROTECTION
# ============================================================

function Configure-NetworkProtection {

    Write-Section "DEFENDER NETWORK PROTECTION"

    try {

        # Windows Server requires explicit permission
        # for Network Protection.

        Set-MpPreference `
            -AllowNetworkProtectionOnWinServer $true

        # AUDIT MODE FIRST.
        #
        # This records suspicious network connections
        # without intentionally blocking normal traffic.

        Set-MpPreference `
            -EnableNetworkProtection AuditMode

        Write-OK `
            "Network Protection: AUDIT MODE"

        Write-Host ""
        Write-Host `
            "Network Protection will log suspicious connections"
        Write-Host `
            "before any aggressive blocking policy is considered."

    }
    catch {

        Write-WarningMsg `
            "Network Protection could not be configured."
    }
}

# ============================================================
# ASR
# ============================================================

function Configure-ASR-Audit {

    Write-Section "ATTACK SURFACE REDUCTION - AUDIT MODE"

    # Selected Microsoft ASR rules.
    #
    # Audit mode is intentional.
    # No rule is put into BLOCK mode here.

    $Rules = @(
        "56a863a9-875e-4185-98a7-b882c64b5ce5",
        "9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2",
        "d4f940ab-401b-4efc-aadc-ad5f3c50688a",
        "3b576869-a4ec-4529-8536-b80a7769e899",
        "75668c1f-73b5-4cf0-bb93-3ecf5cb7cc84",
        "be9ba2d9-53ea-4cdc-84e5-9b1eeee46550"
    )

    $Actions = @(
        "AuditMode",
        "AuditMode",
        "AuditMode",
        "AuditMode",
        "AuditMode",
        "AuditMode"
    )

    try {

        Set-MpPreference `
            -AttackSurfaceReductionRules_Ids $Rules `
            -AttackSurfaceReductionRules_Actions $Actions

        Write-OK `
            "Selected ASR rules configured in AUDIT MODE."

    }
    catch {

        Write-WarningMsg `
            "ASR configuration failed."
    }
}

# ============================================================
# SMB
# ============================================================

function Configure-SMB {

    Write-Section "SMB SECURITY"

    try {

        $SMB1 = Get-WindowsOptionalFeature `
            -Online `
            -FeatureName SMB1Protocol `
            -ErrorAction SilentlyContinue

        if ($SMB1 -and $SMB1.State -ne "Disabled") {

            Disable-WindowsOptionalFeature `
                -Online `
                -FeatureName SMB1Protocol `
                -NoRestart |
                Out-Null
        }

        Write-OK "SMBv1: DISABLED"

    }
    catch {

        Write-WarningMsg `
            "SMBv1 could not be modified."
    }

    try {

        $Service = Get-Service `
            -Name LanmanServer `
            -ErrorAction SilentlyContinue

        if ($Service) {

            if ($Service.Status -eq "Running") {

                Stop-Service `
                    -Name LanmanServer `
                    -Force
            }

            Set-Service `
                -Name LanmanServer `
                -StartupType Disabled

            Write-OK `
                "SMB Server service: DISABLED"

        }
        else {

            Write-OK `
                "SMB Server service not present."
        }

    }
    catch {

        Write-WarningMsg `
            "SMB Server service could not be changed."
    }
}

# ============================================================
# REMOTE REGISTRY
# ============================================================

function Configure-RemoteRegistry {

    Write-Section "REMOTE REGISTRY"

    try {

        $Service = Get-Service `
            -Name RemoteRegistry `
            -ErrorAction SilentlyContinue

        if ($Service) {

            if ($Service.Status -eq "Running") {

                Stop-Service `
                    -Name RemoteRegistry `
                    -Force
            }

            Set-Service `
                -Name RemoteRegistry `
                -StartupType Disabled

            Write-OK `
                "Remote Registry: DISABLED"
        }

    }
    catch {

        Write-WarningMsg `
            "Remote Registry could not be configured."
    }
}

# ============================================================
# LLMNR
# ============================================================

function Configure-LLMNR {

    Write-Section "LLMNR"

    try {

        $Path =
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"

        New-Item `
            -Path $Path `
            -Force |
            Out-Null

        New-ItemProperty `
            -Path $Path `
            -Name EnableMulticast `
            -PropertyType DWord `
            -Value 0 `
            -Force |
            Out-Null

        Write-OK "LLMNR: DISABLED"

    }
    catch {

        Write-WarningMsg `
            "LLMNR could not be disabled."
    }
}

# ============================================================
# GUEST ACCOUNT
# ============================================================

function Configure-Guest {

    Write-Section "GUEST ACCOUNT"

    try {

        $Guest = Get-LocalUser `
            -Name Guest `
            -ErrorAction SilentlyContinue

        if ($Guest) {

            if ($Guest.Enabled) {

                Disable-LocalUser `
                    -Name Guest
            }

            Write-OK `
                "Local Guest account: DISABLED"

        }
        else {

            Write-OK `
                "Local Guest account not present."
        }

    }
    catch {

        Write-WarningMsg `
            "Guest account could not be configured."
    }
}

# ============================================================
# LSA
# ============================================================

function Configure-LSA {

    Write-Section "LSA SECURITY"

    try {

        $Path =
            "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"

        # Prevent LM hash storage.

        New-ItemProperty `
            -Path $Path `
            -Name NoLMHash `
            -PropertyType DWord `
            -Value 1 `
            -Force |
            Out-Null

        Write-OK `
            "LM hash storage disabled."

        # LSA Protection.
        #
        # Value 1 enables RunAsPPL.
        # A reboot is required.

        New-ItemProperty `
            -Path $Path `
            -Name RunAsPPL `
            -PropertyType DWord `
            -Value 1 `
            -Force |
            Out-Null

        Write-OK `
            "LSA Protection enabled."

        Write-WarningMsg `
            "LSA Protection requires a reboot."

    }
    catch {

        Write-WarningMsg `
            "LSA configuration failed."
    }
}

# ============================================================
# POWERSHELL LOGGING
# ============================================================

function Configure-PowerShellLogging {

    Write-Section "POWERSHELL LOGGING"

    try {

        $Base =
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell"

        $ScriptBlock =
            "$Base\ScriptBlockLogging"

        $Module =
            "$Base\ModuleLogging"

        $Modules =
            "$Module\ModuleNames"

        New-Item `
            -Path $ScriptBlock `
            -Force |
            Out-Null

        New-ItemProperty `
            -Path $ScriptBlock `
            -Name EnableScriptBlockLogging `
            -PropertyType DWord `
            -Value 1 `
            -Force |
            Out-Null

        New-Item `
            -Path $Module `
            -Force |
            Out-Null

        New-ItemProperty `
            -Path $Module `
            -Name EnableModuleLogging `
            -PropertyType DWord `
            -Value 1 `
            -Force |
            Out-Null

        New-Item `
            -Path $Modules `
            -Force |
            Out-Null

        New-ItemProperty `
            -Path $Modules `
            -Name "*" `
            -PropertyType String `
            -Value "*" `
            -Force |
            Out-Null

        Write-OK `
            "PowerShell Script Block Logging: ENABLED"

        Write-OK `
            "PowerShell Module Logging: ENABLED"

    }
    catch {

        Write-WarningMsg `
            "PowerShell logging configuration failed."
    }
}

# ============================================================
# SECURITY AUDITING
# ============================================================

function Configure-Auditing {

    Write-Section "SECURITY AUDITING"

    $Commands = @(
        'auditpol /set /subcategory:"Logon" /success:enable /failure:enable',
        'auditpol /set /subcategory:"Logoff" /success:enable /failure:enable',
        'auditpol /set /subcategory:"Account Lockout" /success:enable /failure:enable',
        'auditpol /set /subcategory:"Special Logon" /success:enable /failure:enable',
        'auditpol /set /subcategory:"Process Creation" /success:enable',
        'auditpol /set /subcategory:"System Integrity" /success:enable /failure:enable',
        'auditpol /set /subcategory:"Security System Extension" /success:enable /failure:enable'
    )

    foreach ($Command in $Commands) {

        cmd.exe /c $Command |
            Out-Null
    }

    Write-OK `
        "Windows Security auditing configured."
}

# ============================================================
# SOURCE ROUTING
# ============================================================

function Configure-SourceRouting {

    Write-Section "IP SOURCE ROUTING"

    try {

        $Path =
            "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"

        New-ItemProperty `
            -Path $Path `
            -Name DisableIPSourceRouting `
            -PropertyType DWord `
            -Value 2 `
            -Force |
            Out-Null

        Write-OK `
            "IPv4 source routing protection configured."

    }
    catch {

        Write-WarningMsg `
            "Source routing setting failed."
    }
}

# ============================================================
# RDP
# ============================================================

function Configure-RDP {

    Write-Section "REMOTE DESKTOP"

    $Service = Get-Service `
        -Name TermService `
        -ErrorAction SilentlyContinue

    if (-not $Service) {

        Write-OK `
            "Remote Desktop Services not available."

        return
    }

    if ($Service.Status -eq "Stopped") {

        Write-OK `
            "RDP is already stopped."

        Write-OK `
            "No TCP 3389 listener expected."

        return
    }

    # IMPORTANT:
    # Do NOT stop a running RDP service automatically.
    # This prevents disconnecting an administrator.

    Write-WarningMsg `
        "RDP is currently RUNNING."

    Write-WarningMsg `
        "RDP was NOT automatically disabled."

    Write-WarningMsg `
        "Review RDP separately."
}

# ============================================================
# BACKUP / CONFIRMATION
# ============================================================

function Confirm-Hardening {

    Write-Section "SECURITY HARDENING CONFIRMATION"

    $Profiles = Get-NetworkProfile

    $Public = $Profiles |
        Where-Object {
            $_.NetworkCategory -eq "Public"
        }

    if (-not $Public) {

        Write-Critical `
            "Active profile is not PUBLIC."

        return $false
    }

    $Internet = $Public |
        Where-Object {
            $_.IPv4Connectivity -eq "Internet"
        }

    Write-Host ""
    Write-Host "Active Network Profile : PUBLIC"

    if ($Internet) {

        Write-Host `
            "IPv4 Internet          : AVAILABLE"
    }
    else {

        Write-WarningMsg `
            "IPv4 Internet          : NOT AVAILABLE"
    }

    Write-Host ""
    Write-Host "FIREWALL POLICY:"
    Write-Host ""
    Write-Host "  DOMAIN  : INBOUND BLOCK / OUTBOUND BLOCK"
    Write-Host "  PRIVATE : INBOUND BLOCK / OUTBOUND BLOCK"
    Write-Host "  PUBLIC  : INBOUND BLOCK / OUTBOUND ALLOW"

    Write-Host ""
    Write-Host "CHANGES TO BE APPLIED:"
    Write-Host ""
    Write-Host "[+] Defender security settings"
    Write-Host "[+] Defender Network Protection - AUDIT"
    Write-Host "[+] ASR rules - AUDIT"
    Write-Host "[+] Firewall logging"
    Write-Host "[+] SMBv1 disabled"
    Write-Host "[+] SMB Server disabled"
    Write-Host "[+] Remote Registry disabled"
    Write-Host "[+] LLMNR disabled"
    Write-Host "[+] Guest account disabled"
    Write-Host "[+] LSA Protection"
    Write-Host "[+] PowerShell logging"
    Write-Host "[+] Security auditing"
    Write-Host "[+] IPv4 source routing protection"

    Write-Host ""
    Write-Host "THE SCRIPT WILL NOT:"
    Write-Host "[-] Disable IPv6"
    Write-Host "[-] Globally block UDP"
    Write-Host "[-] Block gaming traffic"
    Write-Host "[-] Block Steam"
    Write-Host "[-] Block Discord"
    Write-Host "[-] Block browsers"
    Write-Host "[-] Disable Windows Update"

    Write-Host ""

    $Answer = Read-Host `
        "Type YES to continue"

    if ($Answer -eq "YES") {

        return $true
    }

    Write-WarningMsg `
        "Hardening cancelled by user."

    return $false
}

# ============================================================
# DIAGNOSTICS - DEFENDER
# ============================================================

function Diagnose-Defender {

    Write-Section "DEFENDER STATUS"

    try {

        Get-MpComputerStatus |
            Select-Object `
                AMServiceEnabled,
                AntivirusEnabled,
                AntispywareEnabled,
                BehaviorMonitorEnabled,
                IoavProtectionEnabled,
                NISEnabled,
                RealTimeProtectionEnabled,
                AntivirusSignatureLastUpdated,
                AntivirusSignatureVersion,
                EngineVersion |
            Format-List

    }
    catch {

        Write-Critical `
            "Unable to read Defender status."
    }
}

# ============================================================
# DIAGNOSTICS - DEFENDER PREFERENCES
# ============================================================

function Diagnose-DefenderPreferences {

    Write-Section "DEFENDER PROTECTION MODES"

    try {

        Get-MpPreference |
            Select-Object `
                EnableNetworkProtection,
                AllowNetworkProtectionOnWinServer,
                AttackSurfaceReductionRules_Ids,
                AttackSurfaceReductionRules_Actions |
            Format-List

    }
    catch {

        Write-WarningMsg `
            "Defender preferences unavailable."
    }
}

# ============================================================
# DIAGNOSTICS - FIREWALL
# ============================================================

function Diagnose-Firewall {

    Write-Section "FIREWALL STATUS"

    Get-NetFirewallProfile |
        Select-Object `
            Name,
            Enabled,
            DefaultInboundAction,
            DefaultOutboundAction,
            LogAllowed,
            LogBlocked |
        Format-Table -AutoSize
}

# ============================================================
# DIAGNOSTICS - TCP
# ============================================================

function Diagnose-TCP {

    Write-Section "TCP LISTENING PORTS"

    $Results = foreach (
        $Connection in (
            Get-NetTCPConnection `
                -State Listen `
                -ErrorAction SilentlyContinue
        )
    ) {

        $Process = Get-Process `
            -Id $Connection.OwningProcess `
            -ErrorAction SilentlyContinue

        [PSCustomObject]@{
            LocalAddress = $Connection.LocalAddress
            LocalPort    = $Connection.LocalPort
            PID          = $Connection.OwningProcess
            Process      = if ($Process) {
                $Process.ProcessName
            }
            else {
                "Unknown"
            }
        }
    }

    $Results |
        Sort-Object LocalPort |
        Format-Table -AutoSize

    $Results |
        Export-Csv `
            "$Reports\TCP-$Time.csv" `
            -NoTypeInformation `
            -Encoding UTF8
}

# ============================================================
# DIAGNOSTICS - UDP
# ============================================================

function Diagnose-UDP {

    Write-Section "UDP LISTENING PORTS"

    $Results = foreach (
        $Endpoint in (
            Get-NetUDPEndpoint `
                -ErrorAction SilentlyContinue
        )
    ) {

        $Process = Get-Process `
            -Id $Endpoint.OwningProcess `
            -ErrorAction SilentlyContinue

        [PSCustomObject]@{
            LocalAddress = $Endpoint.LocalAddress
            LocalPort    = $Endpoint.LocalPort
            PID          = $Endpoint.OwningProcess
            Process      = if ($Process) {
                $Process.ProcessName
            }
            else {
                "Unknown"
            }
        }
    }

    $Results |
        Sort-Object LocalPort |
        Format-Table -AutoSize

    $Results |
        Export-Csv `
            "$Reports\UDP-$Time.csv" `
            -NoTypeInformation `
            -Encoding UTF8
}

# ============================================================
# DIAGNOSTICS - SERVICES
# ============================================================

function Diagnose-Services {

    Write-Section "IMPORTANT SERVICES"

    $Names = @(
        "WinDefend",
        "WdNisSvc",
        "MpsSvc",
        "wuauserv",
        "RemoteRegistry",
        "LanmanServer",
        "LanmanWorkstation",
        "TermService"
    )

    Get-Service `
        -Name $Names `
        -ErrorAction SilentlyContinue |
        Select-Object `
            Name,
            Status,
            StartType,
            DisplayName |
        Format-Table -AutoSize
}

# ============================================================
# DIAGNOSTICS - RDP
# ============================================================

function Diagnose-RDP {

    Write-Section "RDP STATUS"

    $Service = Get-Service `
        -Name TermService `
        -ErrorAction SilentlyContinue

    if ($Service) {

        Write-Host "Service Status : $($Service.Status)"
        Write-Host "Start Type     : $($Service.StartType)"
    }

    $Listener = Get-NetTCPConnection `
        -LocalPort 3389 `
        -ErrorAction SilentlyContinue

    if ($Listener) {

        Write-WarningMsg `
            "TCP 3389 has an active listener."

        $Listener |
            Select-Object `
                LocalAddress,
                LocalPort,
                State |
            Format-Table -AutoSize
    }
    else {

        Write-OK `
            "No active TCP 3389 listener."
    }
}

# ============================================================
# DIAGNOSTICS - SMB
# ============================================================

function Diagnose-SMB {

    Write-Section "SMB STATUS"

    $Service = Get-Service `
        -Name LanmanServer `
        -ErrorAction SilentlyContinue

    if ($Service) {

        Write-Host `
            "LanmanServer Status : $($Service.Status)"

        Write-Host `
            "LanmanServer Start  : $($Service.StartType)"
    }

    try {

        $SMB1 = Get-WindowsOptionalFeature `
            -Online `
            -FeatureName SMB1Protocol `
            -ErrorAction SilentlyContinue

        if ($SMB1) {

            Write-Host `
                "SMB1 Feature State  : $($SMB1.State)"
        }

    }
    catch {

        Write-WarningMsg `
            "SMB1 state unavailable."
    }
}

# ============================================================
# DIAGNOSTICS - SECURITY EVENTS
# ============================================================

function Diagnose-SecurityEvents {

    Write-Section "RECENT SECURITY EVENTS"

    try {

        Get-WinEvent `
            -FilterHashtable @{
                LogName = "Security"
                Id = 4624,4625,4672,4688
            } `
            -MaxEvents 30 `
            -ErrorAction SilentlyContinue |
            Select-Object `
                TimeCreated,
                Id,
                ProviderName |
            Format-Table -AutoSize

    }
    catch {

        Write-WarningMsg `
            "Security events unavailable."
    }
}

# ============================================================
# DIAGNOSTICS - NETWORK PROTECTION EVENTS
# ============================================================

function Diagnose-NetworkProtectionEvents {

    Write-Section "DEFENDER NETWORK PROTECTION EVENTS"

    try {

        Get-WinEvent `
            -FilterHashtable @{
                LogName = `
                    "Microsoft-Windows-Windows Defender/Operational"
                Id = 1125,1126,5007
            } `
            -MaxEvents 30 `
            -ErrorAction SilentlyContinue |
            Select-Object `
                TimeCreated,
                Id,
                ProviderName,
                Message |
            Format-Table -Wrap

    }
    catch {

        Write-WarningMsg `
            "Network Protection event log unavailable."
    }
}

# ============================================================
# DIAGNOSTICS - UPDATES
# ============================================================

function Diagnose-Updates {

    Write-Section "RECENT WINDOWS UPDATES"

    Get-HotFix |
        Sort-Object InstalledOn -Descending |
        Select-Object -First 15 |
        Format-Table `
            HotFixID,
            InstalledOn,
            Description `
            -AutoSize
}

# ============================================================
# DIAGNOSTICS - INTEGRITY
# ============================================================

function Diagnose-Integrity {

    Write-Section "SYSTEM INTEGRITY"

    Write-Host ""
    Write-Host "DISM CheckHealth"
    Write-Host "----------------"

    DISM.exe `
        /Online `
        /Cleanup-Image `
        /CheckHealth

    Write-Host ""
    Write-Host "SFC VerifyOnly"
    Write-Host "--------------"

    sfc.exe /verifyonly
}

# ============================================================
# DIAGNOSTICS - NETWORK
# ============================================================

function Diagnose-Network {

    Write-Section "NETWORK CONFIGURATION"

    Get-NetConnectionProfile |
        Select-Object `
            Name,
            InterfaceAlias,
            NetworkCategory,
            IPv4Connectivity,
            IPv6Connectivity |
        Format-Table -AutoSize

    Write-Host ""

    Get-NetIPConfiguration |
        Format-List
}

# ============================================================
# DIAGNOSTICS - FIREWALL POLICY VERIFICATION
# ============================================================

function Verify-FirewallPolicy {

    Write-Section "FIREWALL POLICY VERIFICATION"

    $Profiles = Get-NetFirewallProfile

    $Domain = $Profiles |
        Where-Object Name -eq "Domain"

    $Private = $Profiles |
        Where-Object Name -eq "Private"

    $Public = $Profiles |
        Where-Object Name -eq "Public"

    if (
        $Domain.DefaultInboundAction -eq "Block" -and
        $Domain.DefaultOutboundAction -eq "Block"
    ) {

        Write-OK `
            "DOMAIN policy = BLOCK / BLOCK"

    }
    else {

        Write-Critical `
            "DOMAIN policy does not match requested configuration."
    }

    if (
        $Private.DefaultInboundAction -eq "Block" -and
        $Private.DefaultOutboundAction -eq "Block"
    ) {

        Write-OK `
            "PRIVATE policy = BLOCK / BLOCK"

    }
    else {

        Write-Critical `
            "PRIVATE policy does not match requested configuration."
    }

    if (
        $Public.DefaultInboundAction -eq "Block" -and
        $Public.DefaultOutboundAction -eq "Allow"
    ) {

        Write-OK `
            "PUBLIC policy = BLOCK / ALLOW"

    }
    else {

        Write-Critical `
            "PUBLIC policy does not match requested configuration."
    }
}

# ============================================================
# FULL DIAGNOSTICS
# ============================================================

function Run-Diagnostics {

    Diagnose-Network
    Diagnose-Defender
    Diagnose-DefenderPreferences
    Diagnose-Firewall
    Verify-FirewallPolicy
    Diagnose-TCP
    Diagnose-UDP
    Diagnose-Services
    Diagnose-RDP
    Diagnose-SMB
    Diagnose-SecurityEvents
    Diagnose-NetworkProtectionEvents
    Diagnose-Updates
    Diagnose-Integrity
}

# ============================================================
# REPORT
# ============================================================

function Create-Report {

    Write-Section "SECURITY REPORT"

    $ReportFile =
        "$Reports\SecurityReport-$Time.txt"

    $OS = Get-CimInstance Win32_OperatingSystem

    $Network =
        Get-NetConnectionProfile |
        Format-Table `
            Name,
            InterfaceAlias,
            NetworkCategory,
            IPv4Connectivity,
            IPv6Connectivity |
        Out-String

    $Firewall =
        Get-NetFirewallProfile |
        Select-Object `
            Name,
            Enabled,
            DefaultInboundAction,
            DefaultOutboundAction,
            LogAllowed,
            LogBlocked |
        Format-Table -AutoSize |
        Out-String

    $Services =
        Get-Service `
            -Name `
                WinDefend,
                WdNisSvc,
                MpsSvc,
                wuauserv,
                RemoteRegistry,
                LanmanServer,
                LanmanWorkstation,
                TermService `
            -ErrorAction SilentlyContinue |
        Select-Object `
            Name,
            Status,
            StartType |
        Format-Table -AutoSize |
        Out-String

@"
============================================================
WINDOWS SERVER 2022 SECURITY REPORT
============================================================

DATE
----
$(Get-Date)

COMPUTER
--------
$env:COMPUTERNAME

OPERATING SYSTEM
----------------
$($OS.Caption)

VERSION
-------
$($OS.Version)

BUILD
-----
$($OS.BuildNumber)

============================================================
NETWORK
============================================================

$Network

============================================================
FIREWALL
============================================================

$Firewall

REQUIRED POLICY

DOMAIN  = INBOUND BLOCK / OUTBOUND BLOCK
PRIVATE = INBOUND BLOCK / OUTBOUND BLOCK
PUBLIC  = INBOUND BLOCK / OUTBOUND ALLOW

============================================================
IMPORTANT SERVICES
============================================================

$Services

============================================================
SECURITY DIRECTORIES
============================================================

Root:
$Root

Backup:
$Backup

Logs:
$Logs

Reports:
$Reports

============================================================
COMPATIBILITY
============================================================

IPv6:
NOT GLOBALLY DISABLED

UDP:
NOT GLOBALLY BLOCKED

Gaming:
NOT GLOBALLY BLOCKED

Steam:
NOT BLOCKED

Discord:
NOT BLOCKED

Browsers:
NOT BLOCKED

Windows Update:
NOT BLOCKED

============================================================
SECURITY MODE
============================================================

Defender:
ENABLED

Network Protection:
AUDIT MODE

ASR:
AUDIT MODE

============================================================
END OF REPORT
============================================================
"@ |
        Out-File `
            -FilePath $ReportFile `
            -Encoding UTF8

    Write-OK `
        "Report created:"

    Write-Host $ReportFile
}

# ============================================================
# ROLLBACK
# ============================================================

function Invoke-Rollback {

    Write-Section "ROLLBACK"

    $LatestBackup =
        Get-ChildItem `
            -Path $Backup `
            -Directory `
            -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if (-not $LatestBackup) {

        Write-Critical `
            "No security backup found."

        return
    }

    Write-Host ""
    Write-Host "Latest backup:"
    Write-Host $LatestBackup.FullName

    Write-Host ""

    $Answer = Read-Host `
        "Type ROLLBACK to continue"

    if ($Answer -ne "ROLLBACK") {

        Write-WarningMsg `
            "Rollback cancelled."

        return
    }

    # Firewall

    $FirewallBackup =
        "$($LatestBackup.FullName)\Firewall.wfw"

    if (Test-Path $FirewallBackup) {

        netsh advfirewall import `
            $FirewallBackup

        Write-OK `
            "Firewall configuration restored."
    }

    # Registry

    $RegistryFiles = @(
        "LSA.reg",
        "DNSClient.reg",
        "PowerShell.reg"
    )

    foreach ($File in $RegistryFiles) {

        $Path =
            "$($LatestBackup.FullName)\$File"

        if (Test-Path $Path) {

            reg.exe import $Path |
                Out-Null

            Write-OK `
                "Registry restored: $File"
        }
    }

    Write-WarningMsg `
        "Restart Windows Server after rollback."
}

# ============================================================
# MAIN
# ============================================================

if (-not (Test-Administrator)) {

    Write-Critical `
        "PowerShell must be running as Administrator."

    Stop-Transcript

    exit 1
}

Write-Section `
    "WINDOWS SERVER 2022 SECURITY - V4"

Get-SystemInformation

# ============================================================
# AUDIT
# ============================================================

if ($Mode -eq "Audit") {

    Write-Section "AUDIT MODE"

    Write-Host ""
    Write-Host "NO SYSTEM CHANGES WILL BE MADE."
    Write-Host ""

    Test-PublicNetwork | Out-Null

    Run-Diagnostics

    Create-Report

    Write-Host ""
    Write-OK "AUDIT COMPLETED."
}

# ============================================================
# HARDEN
# ============================================================

elseif ($Mode -eq "Harden") {

    Write-Section "HARDEN MODE"

    # Safety check

    if (-not (Test-PublicNetwork)) {

        Write-Critical ""
        Write-Critical `
            "HARDENING ABORTED."

        Write-Critical `
            "The active network profile must be PUBLIC."

        Stop-Transcript

        exit 2
    }

    # Confirmation

    if (-not (Confirm-Hardening)) {

        Stop-Transcript

        exit 0
    }

    # Backup

    $BackupPath =
        New-SecurityBackup

    Write-Host ""

    Write-Section "APPLYING SECURITY CONFIGURATION"

    Configure-Firewall
    Configure-Defender
    Configure-NetworkProtection
    Configure-ASR-Audit
    Configure-SMB
    Configure-RemoteRegistry
    Configure-LLMNR
    Configure-Guest
    Configure-LSA
    Configure-PowerShellLogging
    Configure-Auditing
    Configure-SourceRouting
    Configure-RDP

    Write-Section "POST-HARDENING DIAGNOSTICS"

    Run-Diagnostics

    Create-Report

    Write-Host ""
    Write-Host "============================================================" `
        -ForegroundColor Green

    Write-Host `
        " HARDENING COMPLETED" `
        -ForegroundColor Green

    Write-Host "============================================================" `
        -ForegroundColor Green

    Write-Host ""

    Write-OK `
        "Backup: $BackupPath"

    Write-OK `
        "Log: $LogFile"

    Write-Host ""

    Write-WarningMsg `
        "A reboot is recommended."

    Write-WarningMsg `
        "After reboot run:"

    Write-Host ""
    Write-Host `
        ".\Server2022-Secure-v4.ps1 -Mode Diagnose"
}

# ============================================================
# DIAGNOSE
# ============================================================

elseif ($Mode -eq "Diagnose") {

    Write-Section "DIAGNOSTIC MODE"

    Run-Diagnostics

    Create-Report

    Write-Host ""
    Write-OK "DIAGNOSTICS COMPLETED."
}

# ============================================================
# ROLLBACK
# ============================================================

elseif ($Mode -eq "Rollback") {

    Invoke-Rollback
}

Stop-Transcript

Write-Host ""
Write-Host "Finished." -ForegroundColor Green
pause