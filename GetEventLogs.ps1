#use the list or use the computer variable below
$ComputerListFilePath = "c:\ComputerList.txt"
$ComputerList = Get-Content $ComputerListFilePath

#pick a computer or use the list above.
$ComputerName = "wsusmgtprod1"

#By Date
Invoke-Command -ComputerName $ComputerName -Credential $Credentials -ScriptBlock {get-eventlog system -after ([datetime]'9/07/2018 1:00:00 am') -before ([datetime]'9/07/2018 2:00:00 am')| Format-Table -auto -wrap}

#Top 10 System Errors, can filter by EventIDs
Invoke-Command -ComputerName $ComputerName -Credential $Credentials -ScriptBlock {Get-EventLog -LogName System -Newest 10 -EntryType Error | 
where {$_.EventID -ne "" -and $_.EventID -ne ""} | 
Select-Object TimeGenerated,MachineName,EntryType,EventID,Message |
Format-Table -AutoSize -Wrap}