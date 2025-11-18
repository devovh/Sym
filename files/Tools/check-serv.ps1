# Load state from a JSON file
$defaultServices = Get-Content "services_default.json" | ConvertFrom-Json

# Load current state
$currentServices = Get-Service | Select-Object Name, Status, StartType

# Comparison
foreach ($svc in $defaultServices) {
    $current = $currentServices | Where-Object { $_.Name -eq $svc.Name }
    if ($current) {
        if ($current.StartType -ne $svc.StartType) {
            Write-Output "Difference in $($svc.Name): StartType → JSON=$($svc.StartType), Current=$($current.StartType)"
        }
    } else {
        Write-Output "Service $($svc.Name) was not found in the system"
    }
}
Pause