Install-Module -Name Microsoft.OSConfig -Scope AllUsers -Repository PSGallery -Force
Get-Module -ListAvailable -Name Microsoft.OSConfig
Set-OSConfigDesiredConfiguration -Scenario SecurityBaseline/WindowsServer/2025/WorkgroupMember -Default
Set-OSConfigDesiredConfiguration -Scenario SecuredCore -Default
Set-OSConfigDesiredConfiguration -Scenario Defender/Antivirus/WindowsServer/2025 -Default
Set-OSConfigDesiredConfiguration -Scenario SecurityBaseline/WindowsServer/2025/WorkgroupMember -Setting AuditDetailedFileShare -Value 3
Set-OSConfigDesiredConfiguration -Scenario SecurityBaseline/WindowsServer/2025/WorkgroupMember -Name RDSDisallowDriveRedirection -Value 1
Set-OSConfigDesiredConfiguration -Scenario AppControl/WindowsServer/2025/DefaultPolicy/Audit -Default
Set-OSConfigDesiredConfiguration -Scenario AppControl/WindowsServer/2025/AppBlockList/Audit -Default