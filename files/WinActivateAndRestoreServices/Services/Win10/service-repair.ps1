# Path to the original JSON file from a clean system
$inputJsonPath = Join-Path -Path $PSScriptRoot -ChildPath 'services_default.json'

# Path to the sanitized file (optional)
$filteredJsonPath = Join-Path -Path $PSScriptRoot -ChildPath 'services_filtered.json'

Write-Host "Loading service configuration from: $inputJsonPath"

# Load JSON
$services = Get-Content -Path $inputJsonPath | ConvertFrom-Json

# Filter only the services that exist on the current system
$existing = @()
foreach ($s in $services) {
    if (Get-Service -Name $s.Name -ErrorAction SilentlyContinue) {
        $existing += $s
    } else {
        Write-Host "Service $($s.Name) does not exist – skipping."
    }
}

# Save the filtered file (optional)
$existing | ConvertTo-Json -Depth 3 | Out-File -FilePath $filteredJsonPath -Encoding UTF8

Write-Host ""
Write-Host "Restoring service settings..."

foreach ($svc in $existing) {
    $serviceName = $svc.Name
    $desiredStartType = $svc.StartType
    $desiredStatus = $svc.Status

    $currentService = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if ($null -ne $currentService) {
        # Convert startup type to format for sc.exe
        $startTypeParam = switch ($desiredStartType.ToLower()) {
            "automatic" { "auto" }
            "manual"    { "demand" }
            "disabled"  { "disabled" }
            default     { "auto" }
        }

        # Set service startup type
        sc.exe config $serviceName start= $startTypeParam | Out-Null

        # Start or stop the service if needed
        try {
            if ($desiredStatus -eq "Running" -and $currentService.Status -ne "Running") {
                Start-Service -Name $serviceName -ErrorAction Stop
                Write-Host "Service started: $serviceName"
            } elseif ($desiredStatus -eq "Stopped" -and $currentService.Status -ne "Stopped") {
                Stop-Service -Name $serviceName -Force -ErrorAction Stop
                Write-Host "Service stopped: $serviceName"
            } else {
                Write-Host "Service $serviceName is already in the desired state."
            }
        } catch {
            Write-Host ("Failed to change service state {0}: {1}" -f $serviceName, $_)
        }
    }
}

Write-Host ""
Write-Host "Service restoration completed."
Pause