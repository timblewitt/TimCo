@{ 
  AllNodes = @( 
    @{ 
      Nodename = 'localhost'
      PSDscAllowDomainUser = $true
      AdminCreds = 'tim'
    }
  )

  NonNodeData = @{

  OUData = 'OU=Managed',
           'OU=Computers,OU=Managed',
           'OU=Users,OU=Managed',
           'OU=SysAdmins,OU=Users,OU=Managed',
           'OU=AppAdmins,OU=Users,OU=Managed',
           'OU=AppUsers,OU=Users,OU=Managed',
           'OU=Servers,OU=Computers,OU=Managed',
           'OU=Workstations,OU=Computers,OU=Managed'

  UserData = @'
UserName,Password,Dept,Title,Path
Alice,P@ssw0rd,Accounting,Manager,'OU=SysAdmins,OU=Users,OU=Managed'
Bob,P@ssw0rd,IT,Manager,'OU=SysAdmins,OU=Users,OU=Managed'
Charlie,P@ssw0rd,Marketing,Manager,'OU=AppAdmins,OU=Users,OU=Managed'
Debbie,P@ssw0rd,Operations,Manager,'OU=AppAdmins,OU=Users,OU=Managed'
Eddie,P@ssw0rd,Accounting,Specialist,'OU=AppAdmins,OU=Users,OU=Managed'
Frieda,P@ssw0rd,IT,Specialist,'OU=AppUsers,OU=Users,OU=Managed'
George,P@ssw0rd,Marketing,Specialist,'OU=AppUsers,OU=Users,OU=Managed'
Harriet,P@ssw0rd,Operations,Specialist,'OU=AppUsers,OU=Users,OU=Managed'
'@

    }
} 
