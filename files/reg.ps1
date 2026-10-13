Get-AppxPackage -AllUsers | ForEach-Object {
    if ($_.InstallLocation -and (Test-Path "$($_.InstallLocation)\AppXManifest.xml")) {
        Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml" -ErrorAction Continue
    }
}
pause