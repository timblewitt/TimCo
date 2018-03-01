Configuration WebServer
{
Param 
  (
    [string[]]$NodeName,

    [Parameter(Mandatory)]
    [string[]]$DNSServerAddress,
	  
    [Parameter(Mandatory)]
    [String]$DomainName,

    [Parameter(Mandatory)]
    [String]$DomainJoin,

    [Parameter(Mandatory)]
    [System.Management.Automation.PSCredential]$DomainAdmincreds,
	  
    [Int]$RetryCount=30,
    [Int]$RetryIntervalSec=60
  )

Node $AllNodes.NodeName
  {
    WindowsFeature TelnetClient
      {
        Ensure = 'Present'
        Name = 'Telnet-Client'
      }
  }
} 
