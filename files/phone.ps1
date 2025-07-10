Get-AppxPackage Microsoft.YourPhone -AllUsers | Remove-AppxPackage
Get-AppxPackage *CrossDevice* -AllUsers | Remove-AppxPackage -AllUsers
pause