param(
    [parameter(ParameterSetName="ByName",Position=0,Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    [Alias("Computer","Computers")]
    [string[]] $Name,
    [parameter(ParameterSetName="BySession",Position=0,Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    [System.Management.Automation.Runspaces.PSSession[]] $Session)

begin {
    $InstallDir = "\\eu.emory.edu\SystemsTeam\Install\Admin\McAfee"
    $AllSessions = @()
    # Create the script to run on each remote system
    $Script = {
        $RootDirectory = "C:\Admin\McAfee"
        $PowershellPath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
        $CommandPath = "$RootDirectory\Install.ps1"
        $ToRun = "$PowershellPath -File $CommandPath"
    
        $StartTime = $((Get-Date).AddMinutes(-2).ToString('HH:mm'))
        $SchedResults = schtasks.exe /Create /RU "SYSTEM" /RP /SC ONCE /TN "InstallMcAfeeTP" /TR "$ToRun" /ST $StartTime /F /V1 /RL HIGHEST 2>&1
        $SchedResults = schtasks.exe /RUN /TN "InstallMcAfeeTP" 2>&1
    
        # Wait for it to finish
        Write-Host -NoNewline "Installing McAfee."
        do {
            Start-Sleep -Seconds 10
            $Task = ConvertFrom-Csv (schtasks.exe /query /FO CSV /TN "InstallMcAfeeTP")
            Write-Host -NoNewline "."
        } while ($Task.Status -eq "Running")
        Write-Host " Done."
    
        # Delete the task
        $SchedResults = schtasks.exe /DELETE /TN "InstallMcAfeeTP"  /F 2>&1
        
        New-Object PSObject -Property @{
            Name      = $env:COMPUTERNAME
            Complete  = $true
        }
    }
}
process {
    if ($PSCmdlet.ParameterSetName -like "ByName") {
        foreach ($ComputerName in $Name) {
            if ($AllSessions.ComputerName -notcontains $ComputerName) {
                $AllSessions += New-ENTSession -Name $ComputerName
            }
        }
    } else {
        foreach ($Sess in $Session) {
            $AllSessions += $Sess
        }
    }
}
end {
    if ($AllSessions) {
        foreach ($sess IN $AllSessions) {
            if ($sess.ApplicationPrivateData.PSVersionTable.PSVersion.Major -ge 5) {
                Copy-Item -Path $InstallDir -ToSession $sess -Destination "C:\Admin" -Recurse -Force
            } else {
                $credHash = Get-ENTCredential -Computer $sess.ComputerName -ReturnHash
                New-PSDrive -Name TempDrive -PSProvider FileSystem -Root "\\$($sess.ComputerName)\c$" @credHash | Out-Null
        
                Copy-Item -Path $InstallDir -Destination "TempDrive:\Admin" -Recurse -Force
                Remove-PSDrive -Name TempDrive
            }
        }
        
        Invoke-Command -Session $AllSessions -ScriptBlock $Script -HideComputerName |
            Select-Object Name, Complete

        # Now remove the installation files
        # Has to be done from a new session since the files stay open
        $DuplicateSessions = New-PSSession $AllSessions
        Invoke-Command -Session $DuplicateSessions -ScriptBlock {
            Remove-Item "C:\Admin\McAfee" -Recurse -Force
        }
        $DuplicateSessions | Remove-PSSession

        # If we created the PSSession objects in this function, remove them
        if ($PSCmdlet.ParameterSetName -like "ByName") {
            Remove-PSSession -Session $AllSessions
        }
    }
}
