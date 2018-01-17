Configuration Main
{
Param 
  (
    [string[]]$NodeName,

    [Parameter(Mandatory)]
    [string[]]$DNSServerAddress,
	  
    [Parameter(Mandatory)]
    [String]$DomainName,

    [Parameter(Mandatory)]
    [System.Management.Automation.PSCredential]$DomainAdmincreds,
	  
    [Int]$RetryCount=20,
    [Int]$RetryIntervalSec=10
  )

Import-DscResource -ModuleName PSDesiredStateConfiguration
Import-DscResource -ModuleName xNetworking
Import-DscResource -ModuleName xStorage
Import-DscResource -ModuleName xPendingReboot
	
[System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($DomainAdmincreds.UserName)", $DomainAdminCreds.Password)

$Interface = Get-NetAdapter | Where Name -Like "Ethernet*" | Select-Object -First 1
$InterfaceAlias = $($Interface.Name)
	
Node $AllNodes.NodeName
  {
    LocalConfigurationManager            
      {            
        ActionAfterReboot = 'ContinueConfiguration'            
        ConfigurationMode = 'ApplyOnly'            
        RebootNodeIfNeeded = $true      
		AllowModuleOverWrite = $true      
      } 

    xWaitforDisk Disk2
      {
        DiskId = 2
        RetryIntervalSec = $RetryIntervalSec
        RetryCount = $RetryCount
      }

    xDisk FVolume
      {
        DiskId = 2
        DriveLetter = 'F'
      }
	  
    File CreateFile 
      {
        DestinationPath = 'F:\Software\Readme.txt'
        Ensure = "Present"
        Contents = 'Store all software in this folder.'
        DependsOn = "[xDisk]FVolume"
      }
	  
    WindowsFeature TelnetClient
      {
        Ensure = 'Present'
        Name = 'Telnet-Client'
      }
	  
    xDnsServerAddress DNSServer
      {
        Address = $DNSServerAddress
        InterfaceAlias = $InterfaceAlias
        AddressFamily  = "IPv4"
        DependsOn = "[xDisk]FVolume"
      }
	  
    xPendingReboot Reboot1
      { 
        Name = "RebootServer"
        DependsOn = "[xDnsServerAddress]DNSServer"
      }	
  }
} 
