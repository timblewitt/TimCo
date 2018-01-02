Configuration Main
{
Param 
    (
    [string[]]$NodeName = 'localhost',

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
        DiskNumber = 2
          RetryIntervalSec = $RetryIntervalSec
          RetryCount = $RetryCount
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
      }

    xADDomain FirstDC 
      {
        DomainName = $DomainName
        DomainAdministratorCredential = $DomainCreds
        SafemodeAdministratorPassword = $SafeModeAdminCreds
        DatabasePath = "F:\NTDS"
        LogPath = "F:\NTDS"
        SysvolPath = "F:\SYSVOL"
        DependsOn = "[WindowsFeature]ADDSInstall","[xDisk]FVolume"
      }

    xWaitForADDomain DscForestWait
      {
        DomainName = $DomainName
        DomainUserCredential = $DomainCreds
        RetryCount = $RetryCount
        RetryIntervalSec = $RetryIntervalSec
        DependsOn = "[xADDomain]FirstDC"
      } 

    xADRecycleBin RecycleBin
      {
        EnterpriseAdministratorCredential = $DomainCreds
        ForestFQDN = $DomainName
        DependsOn = '[xWaitForADDomain]DscForestWait'
      }

    xADDomainDefaultPasswordPolicy 'DefaultPasswordPolicy'
      {
        DomainName = $DomainName
        ComplexityEnabled = $false
#        MinPasswordLength = "8"
#        LockoutDuration = "60"
#        LockoutObservationWindow = "60"
#        LockoutThreshold = "10"
#        MinPasswordAge = '1440'
#        MaxPasswordAge = '86400'
#        PasswordHistoryCount = "24"
#        ReversibleEncryptionEnabled = $false
        DependsOn = "[xADRecycleBin]RecycleBin"
      }

    xPendingReboot Reboot1
      { 
        Name = "RebootServer"
        DependsOn = "[xADDomainDefaultPasswordPolicy]DefaultPasswordPolicy"
      }

### OUs ###
    $DomainRoot = "DC=$($DomainName -replace '\.',',DC=')"

    ForEach ($OU in $ConfigurationData.NonNodeData.OUData) 
      {        
        If ($OU.Contains(",")) 
          {
            $OUName, $OUPath = $OU.Split(',',2)
            $OUPath = "$OUPath,$DomainRoot"
          }
        Else 
          {
            $OUName = $OU
            $OUPath = $DomainRoot
          }
        $OUName = $OUName.Substring(3)
       
        xADOrganizationalUnit "$OUName"
          {
             Name = $OUName
             Path = $OUPath
             ProtectedFromAccidentalDeletion = $true
             Credential = $DomainCreds
             Ensure = 'Present'
             DependsOn = '[xPendingReboot]Reboot1'
          }
      }

### Users ###
      $DependsOn_User = @()
      $Users = $ConfigurationData.NonNodeData.UserData | ConvertFrom-CSV
      ForEach ($User in $Users) 
        {
          xADUser "NewADUser_$($User.UserName)"
            { 
               DomainName = $DomainName
               Ensure = 'Present'
               UserName = $User.UserName
               GivenName = $User.GivenName
               Surname = $User.Surname
               JobTitle = $User.Title
               Path = "$($User.Path),$DomainRoot"
               Enabled = $true
               Password = New-Object -TypeName PSCredential -ArgumentList 'JustPassword', (ConvertTo-SecureString -String $User.Password -AsPlainText -Force)
               DependsOn = $DependsOn_OU
            }
          $DependsOn_User += "[xADUser]NewADUser_$($User.UserName)"
        }

### Groups ###
      $DependsOn_Group = @()
      $Groups = $ConfigurationData.NonNodeData.GroupData | ConvertFrom-CSV
      ForEach ($Group in $Groups)
        { 
          xADGroup "NewADGroup_$($Group.GroupName)"
            {
               GroupName = $Group.GroupName
               GroupScope = $Group.GroupScope
               Description = $Group.Description
               Category = $Group.Category
               MembersToInclude = $Group.MembersToInclude
#               MembersToInclude = "AA1","BB1","CC1"
#               MembersToInclude = ($Users | Where-Object {$_.UserName -In $Group.MembersToInclude}).UserName
               Path = "$($Group.Path),$DomainRoot"
               Ensure = 'Present'
               DependsOn = $DependsOn_User
            }
          $DependsOn_Group += "[xADGroup]NewADGroup_$($Group.GroupName)"
        }

  }
} 
