# Windows 11 - DLL/OCX Diagnostics
# No DISM, no SFC, no log files, no registry changes
# Run PowerShell as Administrator for best access.

$ErrorActionPreference = "SilentlyContinue"

Clear-Host
Write-Host "=== DLL / OCX DIAGNOSTICS ===" -ForegroundColor Cyan
Write-Host "Read-only scan. No files will be modified.`n"

$folders = @(
    "$env:windir\System32",
    "$env:windir\SysWOW64",
    "$env:ProgramFiles",
    "${env:ProgramFiles(x86)}",
    "$env:LOCALAPPDATA\Programs"
) | Where-Object {
    $_ -and (Test-Path -LiteralPath $_)
} | Select-Object -Unique

$total = 0
$unsigned = 0
$mismatches = 0
$errors = 0

foreach ($folder in $folders) {
    Write-Host "`nScanning: $folder" -ForegroundColor Yellow

    Get-ChildItem -LiteralPath $folder -File -Recurse |
        Where-Object { $_.Extension -in ".dll", ".ocx" } |
        ForEach-Object {
            $file = $_
            $total++

            try {
                $signature = Get-AuthenticodeSignature `
                    -LiteralPath $file.FullName

                switch ($signature.Status.ToString()) {
                    "HashMismatch" {
                        $mismatches++
                        Write-Host "SIGNATURE MISMATCH: $($file.FullName)" `
                            -ForegroundColor Red
                    }
                    "NotSigned" {
                        $unsigned++
                    }
                }
            }
            catch {
                $errors++
            }

            if (($total % 1000) -eq 0) {
                Write-Host "Checked $total files..."
            }
        }
}

Write-Host "`n=== SCAN COMPLETE ===" -ForegroundColor Green
Write-Host "Files checked: $total"
Write-Host "Unsigned files: $unsigned"
Write-Host "Signature mismatches: $mismatches"
Write-Host "Inspection errors: $errors"

Write-Host "`nNo files were repaired, deleted, or registered."
Write-Host "Unsigned files are not necessarily damaged."

Read-Host "`nPress Enter to exit"