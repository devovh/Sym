$stores = Get-ChildItem -Path "Cert:\LocalMachine", "Cert:\CurrentUser" -Recurse | Where-Object { $_.PSIsContainer }

foreach ($store in $stores) {
    $certs = Get-ChildItem -Path $store.PSPath -ErrorAction SilentlyContinue
    if ($certs) {
        foreach ($cert in $certs) {
            if (-not $cert.PSIsContainer) {
                Remove-Item -Path $cert.PSPath -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

certutil -generateSSTFromWU ".\roots.sst"
certutil -addstore -f "Root" ".\roots.sst"
pause