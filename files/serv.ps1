# Pobierz wszystkie usługi
$services = Get-Service | ForEach-Object {
    # Pobierz więcej informacji z WMI (np. opis i typ startu)
    $wmiService = Get-CimInstance -ClassName Win32_Service -Filter "Name = '$($_.Name)'"

    [PSCustomObject]@{
        Name        = $_.Name
        DisplayName = $_.DisplayName
        Status      = $_.Status
        StartType   = $wmiService.StartMode   # np. Automatic, Manual, Disabled
        Description = $wmiService.Description
    }
}

# Zamień na JSON
$json = $services | ConvertTo-Json -Depth 3

# Zapisz do pliku
$json | Out-File -FilePath "C:\services_default.json" -Encoding UTF8

Write-Host "Lista usług zapisana do C:\services_default.json"