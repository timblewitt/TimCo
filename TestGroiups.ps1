$GroupData = @'
GroupName,Category,GroupScope,Path,MembersToInclude,Description
G_SysAdmins,Security,Global,"OU=SysAdmins,OU=Users,OU=Managed","AA1,BB1","Global group for SysAdmins"
G_AppAdmins,Security,Global,"OU=AppAdmins,OU=Users,OU=Managed","CC1","Global group for AppAdmins"
G_AppUsers,Security,Global,"OU=AppUsers,OU=Users,OU=Managed","FF1","Global group for AppUsers"
'@

$Groups = $GroupData | ConvertFrom-Csv
$Groups