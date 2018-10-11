#Remove Active Directory UserID from group "CS All Campus Services"

$UserList = Get-Content "C:\temp\UserList.txt"
$Groups = Get-Content "C:\temp\AllCSGroups.txt"



ForEach ($Group In $Groups)
{
    Remove-ADGroupMember -Identity $Group -Members $UserList -ErrorAction SilentlyContinue
}




Remove-ADGroupMember -Identity "GROUP NAME" -Members $UserList


Get-AdGroup -SearchBase 'OU=Security Groups,OU=Campus Services,DC=Eu,DC=Emory,DC=Edu' | select name,samaccountname