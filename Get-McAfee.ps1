#Get-ENTServerList -Name * -Domain EMORYUNIVAD -NoCampusHosted | Select-Object Name |Export-Csv C:\Users\eusubmatt\Documents\ServerList.csv
$listpath = get-content C:\Users\eusubmatt\Documents\shortlist.txt 
$Servers = $listpath
$Software = Get-ENTSoftware

New-ENTSession $Servers

$Results = foreach ($Server in $Servers) {
    if ($Software -eq "McAfee Agent") {
        Write-Host $Server, $Software} 
    else {Write-Host $Server, "Not Found"}}

$Results | Export-Csv C:\Users\eusubmatt\Documents\Results\McAfeeAgent.csv




