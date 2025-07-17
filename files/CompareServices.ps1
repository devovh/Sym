# Ścieżki do plików JSON
$defaultPath = "./services_default.json"
$updatesPath = "./services_with_updates.json"

# Wczytanie JSON do obiektów PowerShell
$defaultServices = Get-Content $defaultPath | ConvertFrom-Json
$updateServices = Get-Content $updatesPath | ConvertFrom-Json

# Zamiana na słowniki (hashtable) z nazwą usługi jako kluczem
$defaultDict = @{}
foreach ($svc in $defaultServices) {
    $defaultDict[$svc.Name] = $svc
}

$updateDict = @{}
foreach ($svc in $updateServices) {
    $updateDict[$svc.Name] = $svc
}

# Zbiory nazw usług
$defaultNames = $defaultDict.Keys
$updateNames = $updateDict.Keys

# Usługi unikalne dla czystego systemu
$onlyDefault = $defaultNames | Where-Object { $_ -notin $updateNames }

# Usługi unikalne dla systemu po aktualizacjach
$onlyUpdates = $updateNames | Where-Object { $_ -notin $defaultNames }

# Usługi wspólne
$commonNames = $defaultNames | Where-Object { $_ -in $updateNames }

# Porównanie statusu i starttype dla wspólnych usług
$differences = @()
foreach ($name in $commonNames) {
    $svcDefault = $defaultDict[$name]
    $svcUpdate = $updateDict[$name]

    $diffs = @{}

    if ($svcDefault.Status -ne $svcUpdate.Status) {
        $diffs["Status"] = @($svcDefault.Status, $svcUpdate.Status)
    }
    if ($svcDefault.StartType -ne $svcUpdate.StartType) {
        $diffs["StartType"] = @($svcDefault.StartType, $svcUpdate.StartType)
    }

    if ($diffs.Count -gt 0) {
        $differences += [PSCustomObject]@{
            Name = $name
            Differences = $diffs
        }
    }
}

# Wyświetlenie wyników
Write-Host "Usługi tylko w czystym systemie (bez aktualizacji):" $onlyDefault.Count
Write-Host "Usługi tylko w systemie po aktualizacjach:" $onlyUpdates.Count
Write-Host "Usługi ze zmianami w Status lub StartType:" $differences.Count
Write-Host "Wspólna liczba usług:" $commonNames.Count

Write-Host "`nPrzykładowe usługi tylko w czystym systemie:"
$onlyDefault | ForEach-Object { Write-Host $_ }

Write-Host "`nPrzykładowe usługi tylko po aktualizacjach:"
$onlyUpdates | ForEach-Object { Write-Host $_ }

Write-Host "`nPrzykładowe różnice w Status lub StartType:"
$differences | ForEach-Object {
    Write-Host "Nazwa:" $_.Name
    foreach ($k in $_.Differences.Keys) {
        $oldVal = $_.Differences[$k][0]
        $newVal = $_.Differences[$k][1]
        Write-Host ("  {0}: {1} -> {2}" -f $k, $oldVal, $newVal)
    }
}
Pause