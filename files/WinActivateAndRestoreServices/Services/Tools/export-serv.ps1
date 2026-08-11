Get-Service | Select Name, StartType, Status |
  Export-Csv .\current_services.csv -NoTypeInformation
Pause