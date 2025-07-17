# Ścieżka do oryginalnego pliku JSON z czystego systemu
$inputJsonPath = "C:\services_default.json"

# Ścieżka do oczyszczonego pliku (opcjonalnie)
$filteredJsonPath = "C:\services_filtered.json"

Write-Host "Wczytywanie konfiguracji usług z: $inputJsonPath"

# Wczytaj JSON
$services = Get-Content -Path $inputJsonPath | ConvertFrom-Json

# Filtruj tylko te usługi, które istnieją w bieżącym systemie
$existing = @()
foreach ($s in $services) {
    if (Get-Service -Name $s.Name -ErrorAction SilentlyContinue) {
        $existing += $s
    } else {
        Write-Host "Usługa $($s.Name) nie istnieje – pomijam."
    }
}

# Zapisz przefiltrowany plik (opcjonalnie)
$existing | ConvertTo-Json -Depth 3 | Out-File -FilePath $filteredJsonPath -Encoding UTF8

Write-Host ""
Write-Host "Przywracanie ustawień usług..."

foreach ($svc in $existing) {
    $serviceName = $svc.Name
    $desiredStartType = $svc.StartType
    $desiredStatus = $svc.Status

    $currentService = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if ($null -ne $currentService) {
        # Zamień typ startu na format dla sc.exe
        $startTypeParam = switch ($desiredStartType.ToLower()) {
            "automatic" { "auto" }
            "manual"    { "demand" }
            "disabled"  { "disabled" }
            default     { "auto" }
        }

        # Ustaw typ startu usługi
        sc.exe config $serviceName start= $startTypeParam | Out-Null

        # Uruchom lub zatrzymaj usługę, jeśli potrzebne
        try {
            if ($desiredStatus -eq "Running" -and $currentService.Status -ne "Running") {
                Start-Service -Name $serviceName -ErrorAction Stop
                Write-Host "Uruchomiono usługę: $serviceName"
            } elseif ($desiredStatus -eq "Stopped" -and $currentService.Status -ne "Stopped") {
                Stop-Service -Name $serviceName -Force -ErrorAction Stop
                Write-Host "Zatrzymano usługę: $serviceName"
            } else {
                Write-Host "Usługa $serviceName już w odpowiednim stanie."
            }
        } catch {
            Write-Host ("Nie udało się zmienić stanu usługi {0}: {1}" -f $serviceName, $_)
        }
    }
}

Write-Host ""
Write-Host "Zakończono przywracanie usług."
Pause