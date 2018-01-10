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
	  
    [Parameter(Mandatory)]
    [String]$OUPath,

    [Int]$RetryCount=20,
    [Int]$RetryIntervalSec=10
  )

Import-DscResource -ModuleName PSDesiredStateConfiguration
Import-DscResource -ModuleName xComputerManagement
Import-DscResource -ModuleName xNetworking
Import-DscResource -ModuleName xStorage
Import-DscResource -ModuleName xActiveDirectory
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
	  
#    xWaitForADDomain DscForestWait
#	  {
#		DomainName = $DomainName
#        DomainUserCredential= $DomainCreds
#        RetryCount = $RetryCount
#        RetryIntervalSec = $RetryIntervalSec
#	  }
	  
#	xComputer JoinDomain
#      {
#        Name       = $NodeName
#        DomainName = $DomainName
#        Credential = $DomainCreds 
#        DependsOn = "[xWaitForADDomain]DscForestWait"
#      }

#	xADComputer $NodeName
#      {
#		DomainController = '10.0.2.14'
#        DomainAdministratorCredential = $DomainCreds
#        ComputerName = $NodeName
#        Path = $OUPath
#        DependsOn = "[xComputer]JoinDomain"
#      }

    xPendingReboot Reboot1
      { 
        Name = "RebootServer"
        DependsOn = "[xDnsServerAddress]DNSServer"
      }	
  }
} 
