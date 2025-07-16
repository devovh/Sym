# Załaduj stan z pliku JSON
$defaultServices = Get-Content "services_default.json" | ConvertFrom-Json

# Wczytaj bieżący stan
$currentServices = Get-Service | Select-Object Name, Status, StartType

# Porównanie
foreach ($svc in $defaultServices) {
    $current = $currentServices | Where-Object { $_.Name -eq $svc.Name }
    if ($current) {
        if ($current.StartType -ne $svc.StartType) {
            Write-Output "Różnica w $($svc.Name): StartType → JSON=$($svc.StartType), Current=$($current.StartType)"
        }
    } else {
        Write-Output "Usługa $($svc.Name) nie została znaleziona w systemie"
    }
}
Pause