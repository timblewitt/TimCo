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
    [System.Management.Automation.PSCredential]$Admincreds,

    [Parameter(Mandatory)]
    [System.Management.Automation.PSCredential]$SafeModeCreds,

    [Int]$RetryCount=20,
    [Int]$RetryIntervalSec=10
    )

Import-DscResource -ModuleName PSDesiredStateConfiguration
Import-DscResource -ModuleName xStorage
Import-DscResource -ModuleName xNetworking
Import-DscResource -ModuleName xActiveDirectory
Import-DscResource -ModuleName xPendingReboot

[System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $AdminCreds.Password)

[System.Management.Automation.PSCredential ]$SafeModeAdminCreds = New-Object System.Management.Automation.PSCredential ($SafeModeCreds.UserName, $SafeModeCreds.Password)

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
      }

    WindowsFeature TelnetClient
      {
        Ensure = 'Present'
        Name = 'Telnet-Client'
      }
    
    WindowsFeature DNS 
      { 
        Ensure = "Present" 
        Name = "DNS"
      }

    WindowsFeature DNSTools
      { 
        Ensure = 'Present' 
        Name = 'RSAT-DNS-SERVER' 
      }

    WindowsFeature ADDSInstall 
      { 
        Ensure = "Present" 
        Name = "AD-Domain-Services"
      }  

    WindowsFeature ADDSTools
	  { 
        Ensure = 'Present' 
        Name = 'RSAT-ADDS' 
        DependsOn = "[WindowsFeature]ADDSInstall"
      }

	WindowsFeature ADAdminCenter
	  {
		Ensure = "Present"
        Name = "RSAT-AD-AdminCenter"
        DependsOn = "[WindowsFeature]ADDSTools"
	  }

    xDnsServerAddress DNSServer
      {
        Address = $DNSServerAddress
        InterfaceAlias = $InterfaceAlias 
        AddressFamily  = "IPv4"
        DependsOn="[WindowsFeature]ADDSInstall"
      }
	
    xWaitForADDomain DscForestWait
	  {

        DomainName = $DomainName
        DomainUserCredential= $DomainCreds
        RetryCount = $RetryCount
        RetryIntervalSec = $RetryIntervalSec
	  }

    xADDomainController NextDC 
      {
        DomainName = $DomainName
        DomainAdministratorCredential = $DomainCreds
        SafemodeAdministratorPassword = $SafeModeAdminCreds
        DatabasePath = "F:\NTDS"
        LogPath = "F:\NTDS"
        SysvolPath = "F:\SYSVOL"
        DependsOn = "[xWaitForADDomain]DscForestWait"
      }

    xPendingReboot Reboot1
      { 
        Name = "RebootServer"
        DependsOn = "[xADDomainController]NextDC"
      }

  }
} 
