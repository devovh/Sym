# Windows 11 - COM DLL/OCX diagnostics
# No DISM, no SFC, no log files, no automatic mass registration.

$ErrorActionPreference = "SilentlyContinue"
Clear-Host

Write-Host "=== COM DLL/OCX CHECK ===" -ForegroundColor Cyan

$registryRoots = @(
    "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID",
    "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Classes\WOW6432Node\CLSID",
    "Registry::HKEY_CURRENT_USER\Software\Classes\CLSID"
)

$checked = 0
$missing = 0
$missingEntries = [System.Collections.Generic.List[string]]::new()

foreach ($root in $registryRoots) {
    if (-not (Test-Path $root)) { continue }

    Get-ChildItem -LiteralPath $root -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.PSChildName -eq "InprocServer32" } |
        ForEach-Object {
            $key = $_
            $checked++

            $rawPath = (Get-Item -LiteralPath $key.PSPath).GetValue("")

            if (-not $rawPath) { return }

            $path = [Environment]::ExpandEnvironmentVariables(
                [string]$rawPath
            ).Trim().Trim('"')

            # Ignore paths that cannot be checked as ordinary files.
            if ($path -match '^\\\\' -or $path -match '^\\\?\\') {
                return
            }

            if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
                $missing++
                $entry = "$($key.PSPath) -> $path"
                $missingEntries.Add($entry)
                Write-Host "MISSING FILE: $entry" -ForegroundColor Red
            }
        }
}

Write-Host "`n=== RESULTS ===" -ForegroundColor Cyan
Write-Host "COM registrations checked: $checked"
Write-Host "References to missing files: $missing"

if ($missing -gt 0) {
    Write-Host "`nRepair requires the original library or application installer." `
        -ForegroundColor Yellow
    Write-Host "No registry entries or files were changed."
}
else {
    Write-Host "`nNo missing COM library paths were detected." `
        -ForegroundColor Green
    Write-Host "This does not prove that every DLL/OCX is healthy."
}

Read-Host "`nPress Enter to exit"