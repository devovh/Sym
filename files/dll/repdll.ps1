# Windows 11 - Safe DLL/OCX Repair and Diagnostics
# No DISM, no SFC, no log files, no mass registration.
# Registry entries are never deleted or rewritten.

$ErrorActionPreference = "SilentlyContinue"
Clear-Host

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " WINDOWS DLL/OCX SAFE REPAIR TOOL" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "No registry deletion or mass registration."
Write-Host ""

# Check administrator rights
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identity)
$isAdmin = $principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $isAdmin) {
    Write-Host "Please run PowerShell as Administrator." `
        -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit
}

# Locate the registered ENE DRAM RGB MSI product.
$uninstallRoots = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$eneProducts = foreach ($root in $uninstallRoots) {
    Get-ItemProperty $root |
        Where-Object {
            $_.DisplayName -eq "ENE_DRAM_RGB_AIO" -and
            $_.UninstallString -match '\{[0-9A-Fa-f-]{36}\}'
        }
}

# Collect COM registrations
$registryRoots = @(
    "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID",
    "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Classes\WOW6432Node\CLSID",
    "Registry::HKEY_CURRENT_USER\Software\Classes\CLSID"
)

$checked = 0
$missing = [System.Collections.Generic.List[object]]::new()
$untrusted = [System.Collections.Generic.List[string]]::new()

Write-Host "Scanning COM DLL/OCX registrations..." `
    -ForegroundColor Cyan

foreach ($root in $registryRoots) {
    if (-not (Test-Path -LiteralPath $root)) {
        continue
    }

    Get-ChildItem -LiteralPath $root -Recurse |
        Where-Object { $_.PSChildName -eq "InprocServer32" } |
        ForEach-Object {
            $key = $_
            $checked++

            $raw = (Get-Item -LiteralPath $key.PSPath).GetValue("")
            if ([string]::IsNullOrWhiteSpace([string]$raw)) {
                return
            }

            $path = [Environment]::ExpandEnvironmentVariables(
                [string]$raw
            ).Trim().Trim('"')

            # Do not treat remote paths as ordinary local files.
            if ($path -match '^\\\\') {
                return
            }

            if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
                $missing.Add([pscustomobject]@{
                    RegistryKey = $key.Name
                    Path        = $path
                })
                Write-Host "MISSING: $path" -ForegroundColor Yellow
                return
            }

            # Inspect signatures; unsigned does not mean damaged.
            $sig = Get-AuthenticodeSignature -FilePath $path
            if ($sig.Status -eq "HashMismatch") {
                $untrusted.Add($path)
                Write-Host "SIGNATURE HASH MISMATCH: $path" `
                    -ForegroundColor Red
            }
        }
}

Write-Host "`n=============== RESULTS ===============" `
    -ForegroundColor Cyan
Write-Host "COM registrations checked: $checked"
Write-Host "Missing file references: $($missing.Count)"
Write-Host "Signature hash mismatches: $($untrusted.Count)"

if ($untrusted.Count -gt 0) {
    Write-Host "`nWARNING: Do not load or register files with hash mismatches." `
        -ForegroundColor Red
}

# Optional, explicit MSI repair for ENE_DRAM_RGB_AIO only.
if ($eneProducts) {
    Write-Host "`nENE_DRAM_RGB_AIO is registered as installed." `
        -ForegroundColor Cyan
    Write-Host "Version: $($eneProducts[0].DisplayVersion)"
    Write-Host "An MSI repair may restore files from the original package."

    $answer = Read-Host `
        "Run Windows Installer repair for this ENE product? (Y/N)"

    if ($answer -match '^(Y|YES)$') {
        $uninstall = [string]$eneProducts[0].UninstallString
        $match = [regex]::Match(
            $uninstall, '\{[0-9A-Fa-f-]{36}\}'
        )

        if ($match.Success) {
            $productCode = $match.Value
            Write-Host "Starting interactive MSI repair..." `
                -ForegroundColor Yellow

            # Interactive repair. No quiet mode and no forced reboot.
            Start-Process -FilePath "msiexec.exe" `
                -ArgumentList @("/f", "omus", $productCode) -Wait
        }
    }
}
else {
    Write-Host "`nENE MSI product not found; no repair attempted."
}

Write-Host "`n=============== SUMMARY ===============" `
    -ForegroundColor Cyan

if ($missing.Count -gt 0) {
    Write-Host "Some COM paths are missing." -ForegroundColor Yellow
    Write-Host "They were NOT deleted, rewritten or re-registered."
    Write-Host "Use the original vendor installer to restore missing files."
}
else {
    Write-Host "No missing COM paths detected." -ForegroundColor Green
}

Write-Host "`nNo DISM or SFC commands were used."
Write-Host "No log files were created."
Write-Host "No COM registrations were modified."

Read-Host "`nPress Enter to exit"