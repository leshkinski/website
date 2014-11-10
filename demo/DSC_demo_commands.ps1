

# Review current Local Configuration Manager
#
Get-DscLocalConfigurationManager

# Apply DSC configuration
#
Start-DscConfiguration .\myDSCConfig -Wait -Verbose



Test-DscConfiguration -Verbose

Get-DscConfigurationStatus | ft -AutoSize

Get-DscResource
(Get-DscResource User).Properties | ft -AutoSize
