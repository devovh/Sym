# Optymalizacja wydajności karty sieciowej Realtek PCIe GbE (Ethernet)

$adapter = "Ethernet"

# Wyłącz oszczędzanie energii i zbędne funkcje
Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName "Energy-Efficient Ethernet" -DisplayValue "Disabled"
Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName "Flow Control" -DisplayValue "Disabled"
Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName "Interrupt Moderation" -DisplayValue "Disabled"
Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName "Large Send Offload v2 (IPv4)" -DisplayValue "Disabled"
Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName "Large Send Offload v2 (IPv6)" -DisplayValue "Disabled"
Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName "Advanced EEE" -DisplayValue "Disabled"
Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName "Green Ethernet" -DisplayValue "Disabled"
Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName "Gigabit Lite" -DisplayValue "Disabled"
Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName "Power Saving Mode" -DisplayValue "Disabled"
Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName "Wake on Magic Packet" -DisplayValue "Disabled"
Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName "Wake on pattern match" -DisplayValue "Disabled"
Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName "Shutdown Wake-On-Lan" -DisplayValue "Disabled"
Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName "WOL & Shutdown Link Speed" -DisplayValue "Not Speed Down"

# Ustaw pełną prędkość
Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName "Speed & Duplex" -DisplayValue "1.0 Gbps Full Duplex"

# Ustaw bufor na maksimum
Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName "Receive Buffers" -DisplayValue "512"
Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName "Transmit Buffers" -DisplayValue "128"

# Wyłącz offload (opcjonalnie – testuj, czy daje korzyści)
Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName "TCP Checksum Offload (IPv4)" -DisplayValue "Disabled"
Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName "TCP Checksum Offload (IPv6)" -DisplayValue "Disabled"
Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName "UDP Checksum Offload (IPv4)" -DisplayValue "Disabled"
Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName "UDP Checksum Offload (IPv6)" -DisplayValue "Disabled"
Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName "IPv4 Checksum Offload" -DisplayValue "Disabled"

# Zostaw włączone: Receive Side Scaling, RSS Queues, VLAN Priority
Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName "Receive Side Scaling" -DisplayValue "Enabled"
Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName "Maximum Number of RSS Queues" -DisplayValue "4 Queues"
Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName "Priority & VLAN" -DisplayValue "Priority Enabled"

# Potwierdzenie
Write-Host "Zakończono optymalizację interfejsu: $adapter" -ForegroundColor Green
Pause