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
    [System.Management.Automation.PSCredential]$DomainAdmincreds
  )

Import-DscResource -ModuleName PSDesiredStateConfiguration
Import-DscResource -ModuleName xComputerManagement
Import-DscResource -ModuleName xNetworking
Import-DscResource -ModuleName xStorage
Import-DscResource -ModuleName xPendingReboot
	
[System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($DomainAdmincreds.UserName)", $DomainAdminCreds.Password)

$Interface = Get-NetAdapter | Where Name -Like "Ethernet*" | Select-Object -First 1
$InterfaceAlias = $($Interface.Name)

Node $NodeName
    {
    xDnsServerAddress DNSServer
      {
        Address = $DNSServerAddress
        InterfaceAlias = $InterfaceAlias
        AddressFamily  = "IPv4"
      }

    WindowsFeature TelnetClient
      {
        Ensure = 'Present'
        Name = 'Telnet-Client'
      }

    xWaitforDisk Disk2
      {
        DiskNumber = 2
        RetryIntervalSec = 60
      }

    xDisk FVolume
      {
        DiskNumber = 2
        DriveLetter = 'F'
      }

    File CreateFile 
      {
        DestinationPath = 'F:\Software\Readme.txt'
        Ensure = "Present"
        Contents = 'Store all software in this folder.'
        DependsOn = "[xDisk]FVolume"
      }

    xPendingReboot Reboot1
      { 
        Name = "RebootServer"
        DependsOn = "[xDisk]FVolume"
      }
		
	xComputer JoinDomain
      {
        Name       = $NodeName
        DomainName = $DomainName
        Credential = $DomainCreds 
        DependsOn = "[xPendingReboot]Reboot1"
        }

    }
} 
