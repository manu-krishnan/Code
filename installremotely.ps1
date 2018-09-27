# To install Chocolatey, and install an MSI
#Found on Spiceworks: https://community.spiceworks.com/canonical_answer_pages/6864-install-msi-to-a-remote-pc?utm_source=copy_paste&utm_campaign=growth

$ComputerListPath = "C:\temp\ServerList.txt"
$ComputerList = Get-Content $ComputerListPath
$Credential = Get-Credential

#install chocolatey only
Invoke-Command -ComputerName $ComputerList -Credential $Credential -ScriptBlock {iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))}
               


#install chocolatey and then install MSI. Be sure to specify your MSI either via URL or filepath
Invoke-Command -ComputerName $ComputerList -Credential $Credential -ScriptBlock {iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
            choco install <#YourMSIhere#> -y}
   