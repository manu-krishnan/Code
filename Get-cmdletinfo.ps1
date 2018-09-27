#Dig into what a cmdlet is calling on. CommandType shows the .net class
#also => https://msdn.microsoft.com/en-us/library/gg145045%28v=vs.110%29.aspx
#also => [System.String] | Get-Member
    # [System.String].GetMethod("Clone")
    
function Get-cmdletinfo () {
        param([Parameter(Mandatory)]$cmdlet)    
    
    (Get-Command $cmdlet) | Format-List Name,CommandType,DLL,ImplementingType
}
