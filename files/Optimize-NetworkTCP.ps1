# Plik logu
$logFile = "C:\NetworkOptimizationLog.txt"
Start-Transcript -Path $logFile -Append

Write-Host ""
Write-Host "Optymalizacja TCP/IP i ustawień sieciowych dla Windows Server 2022"
Write-Host ""

# Włącz Receive Side Scaling (RSS)
Write-Host "Włączanie Receive Side Scaling (RSS)..."
Get-NetAdapter | ForEach-Object {
    Enable-NetAdapterRss -Name $_.Name -ErrorAction SilentlyContinue
}

# Włącz Receive Segment Coalescing (RSC), jeśli dostępne
Write-Host "Włączanie Receive Segment Coalescing (RSC)..."
Get-NetAdapter | ForEach-Object {
    try {
        Enable-NetAdapterRsc -Name $_.Name -ErrorAction Stop
    } catch {
        Write-Host "RSC niedostępne dla: $($_.Name)"
    }
}

# Włącz TCP autotuning
Write-Host "Ustawienie Receive Window Auto-Tuning na: normal"
netsh int tcp set global autotuninglevel=normal

# Włącz ECN
Write-Host "Włączanie ECN Capability"
netsh int tcp set global ecncapability=enabled

# Włącz TCP timestamps
Write-Host "Włączanie RFC1323 timestamps"
netsh int tcp set global timestamps=enabled

# Włącz TCP Fast Open
Write-Host "Włączanie TCP Fast Open"
netsh int tcp set global fastopen=enabled

# Ustaw CTCP na profilu internet (bez zmiany trybu automatycznego)
Write-Host "Ustawianie CTCP congestion provider na profilu internet"
netsh int tcp set supplemental template=internet congestionprovider=ctcp

# Pokaż aktualne ustawienia globalne TCP
Write-Host ""
Write-Host "Aktualna konfiguracja TCP:"
netsh int tcp show global

Write-Host ""
Write-Host "Optymalizacja zakończona. Szczegóły zapisano w: $logFile"

Stop-Transcript
pause