#Add Active Directory UserID to group "CS All Campus Services"

$UserList = "C:\temp\UserList.txt"
$User = Get-Content $UserList

Add-ADGroupMember -Identity "GROUP NAME" -Members $User