Install-Module -Name Microsoft.OSConfig -Scope AllUsers -Repository PSGallery -Force
Get-Module -ListAvailable -Name Microsoft.OSConfig
Set-OSConfigDesiredConfiguration -Scenario SecurityBaseline/WS2025/WorkgroupMember -Default
Set-OSConfigDesiredConfiguration -Scenario SecuredCore -Default
Set-OSConfigDesiredConfiguration -Scenario Defender/Antivirus -Default
Set-OSConfigDesiredConfiguration -Scenario SecurityBaseline/WS2025/WorkgroupMember -Setting AuditDetailedFileShare -Value 3
Set-OSConfigDesiredConfiguration -Scenario SecurityBaseline/WS2025/WorkgroupMember -Name RemoteDesktopServicesDoNotAllowDriveRedirection -Value 0
Set-OSConfigDesiredConfiguration -Scenario AppControl\WS2025\DefaultPolicy\Audit -Default
Set-OSConfigDesiredConfiguration -Scenario AppControl\WS2025\AppBlockList\Audit -Default