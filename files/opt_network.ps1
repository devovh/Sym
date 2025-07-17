$adapterName = "Ethernet"

$settings = @{
    "Energy-Efficient Ethernet"                                   = "Disabled"
    "Flow Control"                                                = "Disabled"
    "Interrupt Moderation"                                        = "Disabled"
    "IPv4 Checksum Offload"                                       = "Disabled"
    "Jumbo Frame"                                                 = "Disabled"
    "Large Send Offload v2 (IPv4)"                                = "Disabled"
    "Large Send Offload v2 (IPv6)"                                = "Disabled"
    "Wake on magic packet when system is in the S0ix power state" = "Disabled"
    "Maximum Number of RSS Queues"                                = "4 Queues"
    "ARP Offload"                                                 = "Disabled"
    "NS Offload"                                                  = "Disabled"
    "Priority & VLAN"                                             = "Priority & VLAN Disabled"
    "Receive Buffers"                                             = "512"
    "Receive Side Scaling"                                        = "Enabled"
    "Speed & Duplex"                                              = "1.0 Gbps Full Duplex"
    "TCP Checksum Offload (IPv4)"                                 = "Rx & Tx Enabled"
    "TCP Checksum Offload (IPv6)"                                 = "Rx & Tx Enabled"
    "Transmit Buffers"                                            = "128"
    "UDP Checksum Offload (IPv4)"                                 = "Rx & Tx Enabled"
    "UDP Checksum Offload (IPv6)"                                 = "Rx & Tx Enabled"
    "Wake on Magic Packet"                                        = "Disabled"
    "Wake on pattern match"                                       = "Disabled"
    "Advanced EEE"                                                = "Disabled"
    "Auto Disable Gigabit"                                        = "Disabled"
    "Green Ethernet"                                              = "Disabled"
    "Gigabit Lite"                                                = "Disabled"
    "Power Saving Mode"                                           = "Disabled"
    "Shutdown Wake-On-Lan"                                        = "Disabled"
    "WOL & Shutdown Link Speed"                                   = "Not Speed Down"
    "VLAN ID"                                                     = "0"
}

Write-Host "Rozpoczynam optymalizację ustawień Ethernet dla interfejsu: $adapterName`n"

foreach ($name in $settings.Keys) {
    try {
        Write-Host "Ustawianie: $name na '$($settings[$name])'" -ForegroundColor Cyan
        Set-NetAdapterAdvancedProperty -Name $adapterName -DisplayName $name -DisplayValue $settings[$name] -NoRestart -ErrorAction Stop
    } catch {
        Write-Warning "Nie udało się ustawić '$name': $($_.Exception.Message)"
    }
}

Write-Host "Optymalizacja zakończona. Zalecany restart systemu." -ForegroundColor Green
Pause