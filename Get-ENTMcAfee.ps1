<#
McAfee Agent
McAfee Agent Handler
McAfee Endpoint Security Platform
McAfee Endpoint Security Threat Prevention
McAfee ePolicy Orchestrator
McAfee ePolicy Orchestrator 5.9.0
McAfee Security Scan Plus
McAfee VirusScan Enterprise


$listpath = get-content C:\Users\eusubmatt\Documents\shortlist.txt 
    $list = $listpath


function test {
        param(
            $computername =$env:computername
             )

        foreach ($computer in $computername){ 
            $appList = @("McAfee Agent","McAfee Agent Handler","McAfee Endpoint Security Platform","McAfee Endpoint Security Threat Prevention","McAfee ePolicy Orchestrator","McAfee ePolicy Orchestrator 5.9.0","McAfee Security Scan Plus","McAfee VirusScan Enterprise")
            $installedAppz = Get-ENTSoftware -Computers $list -ErrorAction SilentlyContinue
            $myhash = @{}
            $installedApps = $installedApps.software | sort software | select -Unique
            [bool]$installed = $false

                foreach($app in $appList)
                {
                    foreach($installedApp in $installedApps)
                    {
                        if($installedApp.DisplayName -like "*$app*")
                        {
                            $installed = $true
                        }
                    }
                        if($installed -eq $false)
                        {
                            Write-Host $computer "Missing $app"
                        }
                    $installed = $false
                }
            }
        }




        function test {
    $data = Get-ENTSoftware -Computers $list -ErrorAction SilentlyContinue
    $myhash = @{}    
    $keys = $data.computer | sort computer | select -Unique
    foreach ($key in $keys){
        $myhash[$key] = $false
    }

        foreach ($data.software in $data) {
            if ($Software -eq 'McAfee Agent' )
            {
                    $myhash[$software] = $true
            }
        }
        return $myhash
}

#>
<#
function Get-ENTMcAfee {
        param(
            $computername =$env:computername
             )
    $data = Get-ENTSoftware -Computers $list -ErrorAction SilentlyContinue
    $myhash = @{}
    $keys = $data.software | sort software | select -Unique
    foreach ($computer in $computername) 
    {  

        foreach ($key in $keys) 
        {

            if ($key -eq ('McAfee Agent')) 
            {write-host $computer "McAfee Agent Present"}

            elseif ($key -eq ('McAfee Agent Handler')) 
            {write-host $computer "McAfee Agent Handler Present"}

            elseif ($key -eq ('McAfee Endpoint Security Platform')) 
            {write-host $computer "McAfee Endpoint Security Platform Present"}

            elseif ($key -eq ('McAfee Endpoint Security Threat Prevention')) 
            {write-host $computer "McAfee Endpoint Security Threat Prevention Present"}

            elseif ($key -eq ('McAfee ePolicy Orchestrator')) 
            {write-host $computer "McAfee Endpoint Security Threat Prevention Present"}
        
            elseif ($key -eq ('McAfee ePolicy Orchestrator 5.9.0')) 
            {write-host $computer "McAfee ePolicy Orchestrator 5.9.0 Present"}

            elseif ($key -eq ('McAfee Security Scan Plus')) 
            {write-host $computer "McAfee Security Scan Plus Present"}

            elseif ($key -eq ('McAfee VirusScan Enterprise')) 
            {write-host $computer "McAfee VirusScan Enterprise Present"}
     
        }
    }
}
#>

#What I actually used in the end. Compared excel file results from each software search
$serverlistpath = get-content C:\Users\eusubmatt\Documents\serverlist.txt 
$serverlist = $serverlistpath

Get-ENTSoftware -Computers $serverlist -ErrorAction SilentlyContinue | Export-Csv C:\Users\eusubmatt\Documents\McAfee\All.csv
Get-ENTSoftware -Computers $serverlist -Filter 'McAfee Agent' -ErrorAction SilentlyContinue| Export-Csv C:\Users\eusubmatt\Documents\McAfee\McAfee_Agent.csv
Get-ENTSoftware -Computers $serverlist -Filter 'McAfee Agent Handler' -ErrorAction SilentlyContinue| Export-Csv C:\Users\eusubmatt\Documents\McAfee\McAfee_Agent_Handler.csv
Get-ENTSoftware -Computers $serverlist -Filter 'McAfee Endpoint Security Platform' -ErrorAction SilentlyContinue| Export-Csv C:\Users\eusubmatt\Documents\McAfee\McAfee_Endpoint_Security_Platform.csv
Get-ENTSoftware -Computers $serverlist -Filter 'McAfee Endpoint Security Threat Prevention' -ErrorAction SilentlyContinue| Export-Csv C:\Users\eusubmatt\Documents\McAfee\McAfee_Endpoint_Security_Threat_Prevention.csv
Get-ENTSoftware -Computers $serverlist -Filter 'McAfee ePolicy Orchestrator' -ErrorAction SilentlyContinue| Export-Csv C:\Users\eusubmatt\Documents\McAfee\McAfee_ePolicy_Orchestrator.csv
Get-ENTSoftware -Computers $serverlist -Filter 'McAfee ePolicy Orchestrator 5.9.0' -EerrorAction SilentlyContinue| Export-Csv C:\Users\eusubmatt\Documents\McAfee\McAfee_ePolicy_Orchestrator_5.9.0.csv
Get-ENTSoftware -Computers $serverlist -Filter 'McAfee Security Scan Plus' -ErrorAction SilentlyContinue| Export-Csv C:\Users\eusubmatt\Documents\McAfee\McAfee_Security_Scan_Plus.csv
Get-ENTSoftware -Computers $serverlist -Filter 'McAfee VirusScan Enterprise' -ErrorAction SilentlyContinue| Export-Csv C:\Users\eusubmatt\Documents\McAfee\McAfee_VirusScan_Enterprise.csv
Get-ENTSoftware -Computers $serverlist -Filter McAfee -ErrorAction SilentlyContinue| Export-Csv C:\Users\eusubmatt\Documents\McAfee\McAfee.csv







$All = Import-Csv -Path C:\Users\eusubmatt\Documents\McAfee\All.csv
$McAfee = Import-Csv -Path C:\Users\eusubmatt\Documents\McAfee\McAfee.csv
Compare-Object $All $McAfee | Export-Csv C:\Users\eusubmatt\Documents\McAfee\ComparisonResults\McAfee.csv 
