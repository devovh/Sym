#requires -RunAsAdministrator

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "========================================================" -ForegroundColor Red
Write-Host " WINDOWS SERVER 2022 - CERTIFICATE RESET" -ForegroundColor Red
Write-Host "========================================================" -ForegroundColor Red
Write-Host ""

$confirm = Read-Host "Type DELETE to continue"

if ($confirm -ne "DELETE") {
    Write-Host "Cancelled." -ForegroundColor Yellow
    exit
}

# ========================================================
# FUNCTION: REMOVE CERTIFICATES FROM CERT PROVIDER:
# ========================================================

function Remove-AllCertificates {
    param(
        [Parameter(Mandatory)]
        [string]$BasePath
    )

    Write-Host ""
    Write-Host ">>> CLEANING $BasePath" -ForegroundColor Cyan

    $certs = @(
        Get-ChildItem `
            -Path $BasePath `
            -Recurse `
            -Force `
            -ErrorAction SilentlyContinue |
        Where-Object {
            -not $_.PSIsContainer -and
            $_.PSObject.Properties["Thumbprint"]
        }
    )

    Write-Host "Found: $($certs.Count)" -ForegroundColor Yellow

    foreach ($cert in $certs) {

        Write-Host "Removing: $($cert.Subject)" -ForegroundColor DarkYellow

        try {
            Remove-Item `
                -LiteralPath $cert.PSPath `
                -Force `
                -ErrorAction Stop

            Write-Host "  OK" -ForegroundColor Green
        }
        catch {
            Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# ========================================================
# 1. LOCAL MACHINE = certlm.msc
# ========================================================

Remove-AllCertificates "Cert:\LocalMachine"

# ========================================================
# 2. CURRENT USER = certmgr.msc
# ========================================================

Remove-AllCertificates "Cert:\CurrentUser"

# ========================================================
# 3. REMOVE CTL
#
# Disallowed = Untrusted Certificates
# AuthRoot   = Third-Party Root Certification Authorities
# ========================================================

Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host " REMOVING CTL / CRL" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

# First, check whether certmgr.exe is available

$certmgr = Get-Command certmgr.exe -ErrorAction SilentlyContinue

if ($certmgr) {

    Write-Host "certmgr.exe: $($certmgr.Source)" -ForegroundColor Green

    # Local Machine - Disallowed CTL
    Write-Host "Removing LocalMachine Disallowed CTL..." -ForegroundColor Yellow

    & $certmgr.Source `
        -del `
        -all `
        -ctl `
        -s `
        -r localMachine `
        Disallowed

    # Local Machine - AuthRoot CTL
    Write-Host "Removing LocalMachine AuthRoot CTL..." -ForegroundColor Yellow

    & $certmgr.Source `
        -del `
        -all `
        -ctl `
        -s `
        -r localMachine `
        AuthRoot

    # Current User - Disallowed CTL
    Write-Host "Removing CurrentUser Disallowed CTL..." -ForegroundColor Yellow

    & $certmgr.Source `
        -del `
        -all `
        -ctl `
        -s `
        -r currentUser `
        Disallowed

    # Current User - AuthRoot CTL
    Write-Host "Removing CurrentUser AuthRoot CTL..." -ForegroundColor Yellow

    & $certmgr.Source `
        -del `
        -all `
        -ctl `
        -s `
        -r currentUser `
        AuthRoot
}
else {

    Write-Host ""
    Write-Host "certmgr.exe not found." -ForegroundColor Yellow
    Write-Host "Skipping CTL removal safely." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "If you want to remove CTLs, install the Windows SDK." -ForegroundColor Yellow
}

# ========================================================
# 4. ADDITIONAL CRL / CTL REMOVAL USING CERTUTIL
# ========================================================

Write-Host ""
Write-Host "Removing additional Disallowed entries..." -ForegroundColor Yellow

certutil -delstore Disallowed * 2>$null

Write-Host "Removing additional AuthRoot entries..." -ForegroundColor Yellow

certutil -delstore AuthRoot * 2>$null

# ========================================================
# 5. VERIFICATION AFTER CLEANUP
# ========================================================

Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host " VERIFICATION AFTER CLEANUP" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

Write-Host ""
Write-Host "--- LocalMachine Root ---" -ForegroundColor Yellow
certutil -store Root

Write-Host ""
Write-Host "--- LocalMachine CA ---" -ForegroundColor Yellow
certutil -store CA

Write-Host ""
Write-Host "--- LocalMachine AuthRoot ---" -ForegroundColor Yellow
certutil -store AuthRoot

Write-Host ""
Write-Host "--- LocalMachine Disallowed ---" -ForegroundColor Yellow
certutil -store Disallowed

# ========================================================
# 6. GENERATE A FRESH ROOT.SST
# ========================================================

Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host " DOWNLOADING FRESH ROOT CAs FROM WINDOWS UPDATE" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

$SST = Join-Path $PSScriptRoot "roots.sst"

if (Test-Path $SST) {
    Remove-Item $SST -Force
}

Write-Host "Generating: $SST" -ForegroundColor Yellow

certutil -generateSSTFromWU $SST

if (-not (Test-Path $SST)) {
    Write-Host ""
    Write-Host "ERROR: Windows Update did not generate roots.sst." -ForegroundColor Red
    pause
    exit 1
}

Write-Host ""
Write-Host "[OK] roots.sst created." -ForegroundColor Green

# ========================================================
# 7. ADD ROOT CAs
# ========================================================

Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host " ADDING ROOT CAs" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

certutil -addstore -f Root $SST

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "[OK] Root CAs were added successfully." -ForegroundColor Green
}
else {
    Write-Host ""
    Write-Host "[ERROR] Failed to add Root CAs." -ForegroundColor Red
}

# ========================================================
# 8. FINAL VERIFICATION
# ========================================================

Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host " FINAL VERIFICATION" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

Write-Host ""
Write-Host "--- ROOT ---" -ForegroundColor Yellow
certutil -store Root

Write-Host ""
Write-Host "--- AUTHROOT ---" -ForegroundColor Yellow
certutil -store AuthRoot

Write-Host ""
Write-Host "--- DISALLOWED ---" -ForegroundColor Yellow
certutil -store Disallowed

Write-Host ""
Write-Host "--- CA ---" -ForegroundColor Yellow
certutil -store CA

Write-Host ""
Write-Host "========================================================" -ForegroundColor Green
Write-Host " COMPLETED" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
Write-Host ""
Write-Host "roots.sst: $SST" -ForegroundColor White
Write-Host ""
Write-Host "Close and reopen certlm.msc." -ForegroundColor Yellow
Write-Host ""

pause