Configuration Main
{
Param 
    (
    [string[]]$NodeName
    )

Import-DscResource -ModuleName xStorage
Import-DscResource -ModuleName xNetworking

Node $nodeName
    {
    xFirewall AllowPing
        {
        Name = "vm-monitoring-icmpv4"
        Ensure = "Present"
        Enabled = "True"
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

    WindowsFeature TelnetClient
        {
        Ensure = 'Present'
        Name = 'Telnet-Client'
        }

    File CreateFile 
	{
        DestinationPath = 'F:\Software\Readme.txt'
        Ensure = "Present"
        Contents = 'Store all software in this folder.'
        }
    }
} 
