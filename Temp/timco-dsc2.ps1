Configuration WebServer
{
Param 
  (
    [string[]]$NodeName
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
