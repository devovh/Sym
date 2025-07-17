# Wczytaj pliki JSON
$defaultPath = "services_default.json"
$updatedPath = "services_with_updates.json"

# Wczytaj dane z plików
$defaultServices = Get-Content $defaultPath | ConvertFrom-Json
$updatedServices = Get-Content $updatedPath | ConvertFrom-Json

# Wyciągnij nazwy usług
$defaultNames = $defaultServices | ForEach-Object { $_.Name }
$updatedNames = $updatedServices | ForEach-Object { $_.Name }

# Przekształć na zestawy unikalne
$defaultSet = $defaultNames | Sort-Object -Unique
$updatedSet = $updatedNames | Sort-Object -Unique

# Policz liczby
$defaultCount = $defaultSet.Count
$updatedCount = $updatedSet.Count

# Wspólne i unikalne
$common = $defaultSet | Where-Object { $updatedSet -contains $_ }
$onlyInDefault = $defaultSet | Where-Object { $updatedSet -notcontains $_ }
$onlyInUpdated = $updatedSet | Where-Object { $defaultSet -notcontains $_ }

# Wyniki w konsoli
Write-Host "Usługi w services_default.json: $defaultCount"
Write-Host "Usługi w services_with_updates.json: $updatedCount"
Write-Host "Wspólne usługi: $($common.Count)"
Write-Host "Tylko w default.json: $($onlyInDefault.Count)"
Write-Host "Tylko w updated.json: $($onlyInUpdated.Count)"

# Zapisz do plików CSV
$onlyInDefault | ForEach-Object { [PSCustomObject]@{ServiceName = $_} } | Export-Csv -Path "OnlyInDefault.csv" -NoTypeInformation -Encoding UTF8
$onlyInUpdated | ForEach-Object { [PSCustomObject]@{ServiceName = $_} } | Export-Csv -Path "OnlyInUpdated.csv" -NoTypeInformation -Encoding UTF8
$common | ForEach-Object { [PSCustomObject]@{ServiceName = $_} } | Export-Csv -Path "CommonServices.csv" -NoTypeInformation -Encoding UTF8

Write-Host "`nPełne różnice zostały zapisane:"
Write-Host "  • OnlyInDefault.csv"
Write-Host "  • OnlyInUpdated.csv"
Write-Host "  • CommonServices.csv"
Pause