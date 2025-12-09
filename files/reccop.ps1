dism /Online /Disable-Feature /FeatureName:Recall /Remove
Get-AppxPackage -Name *Copilot* | Remove-AppxPackage -AllUsers
pause