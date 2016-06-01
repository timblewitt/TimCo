﻿@{ 
    AllNodes = @( 
        @{ 
            Nodename = 'localhost'
            PSDscAllowDomainUser = $true
            AdminCreds = 'tim'
        }
    )

    NonNodeData = @{

        UserData = @'
UserName,Password,Dept,Title
Alice,P@ssw0rd,Accounting,Manager
Bob,P@ssw0rd,IT,Manager
Charlie,P@ssw0rd,Marketing,Manager
Debbie,P@ssw0rd,Operations,Manager
Eddie,P@ssw0rd,Accounting,Specialist
Frieda,P@ssw0rd,IT,Specialist
George,P@ssw0rd,Marketing,Specialist
Harriet,P@ssw0rd,Operations,Specialist
'@

  OUData = 'OU=Computers,OU=Managed',
           'OU=Users,OU=Managed',
           'OU=SysAdmins,OU=Users,OU=Managed',
           'OU=AppAdmins,OU=Users,OU=Managed',
           'OU=AppUsers,OU=Users,OU=Managed',
           'OU=Servers,OU=Computers,OU=Managed',
           'OU=Workstations,OU=Computers,OU=Managed'

    }
} 
