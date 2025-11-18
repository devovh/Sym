Get-AppxPackage -AllUsers | Foreach {
    Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppxManifest.xml"
}
Read-Host "Enter"