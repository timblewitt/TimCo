@{ 
  AllNodes = @( 
    @{ 
      Nodename = 'localhost'
#      PSDscAllowDomainUser = $true
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
UserName,Password,GivenName,Surname,Dept,Title,Path
AA1,P@ssw0rd,Andrew,Aardvark,Accounting,Manager,"OU=SysAdmins,OU=Users,OU=Managed"
BB1,P@ssw0rd,Beth,Buffalo,IT,Manager,"OU=SysAdmins,OU=Users,OU=Managed"
CC1,P@ssw0rd,Chris,Crocodile,Marketing,Manager,"OU=AppAdmins,OU=Users,OU=Managed"
DD1,P@ssw0rd,Doris,DikDik,Operations,Manager,"OU=AppAdmins,OU=Users,OU=Managed"
EE1,P@ssw0rd,Edward,Elephant,Accounting,Specialist,"OU=AppAdmins,OU=Users,OU=Managed"
FF1,P@ssw0rd,Florence,Flamingo,IT,Specialist,"OU=AppUsers,OU=Users,OU=Managed"
GG1,P@ssw0rd,Graham,Gazelle,Marketing,Specialist,"OU=AppUsers,OU=Users,OU=Managed"
HH1,P@ssw0rd,Helen,Hippo,Operations,Specialist,"OU=AppUsers,OU=Users,OU=Managed"
'@

  GroupData = @'
GroupName,Category,GroupScope,Path,MembersToInclude,Description
G_SysAdmins,Security,Global,"OU=SysAdmins,OU=Users,OU=Managed","{AA1,BB1}","Global group for SysAdmins"
G_AppAdmins,Security,Global,"OU=AppAdmins,OU=Users,OU=Managed","(CC1,DD1,EE1)","Global group for AppAdmins"
G_AppUsers,Security,Global,"OU=AppUsers,OU=Users,OU=Managed","FF1,GG1,HH1","Global group for AppUsers"
'@
    }
} 
