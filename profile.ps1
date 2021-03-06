##Basic Startup
cd \

#Credentials
$ComputerName = ""
$Username = "emoryunivad\eusubmatt"
$Password = Get-Content 'C:\Users\eusubmatt\Documents\WindowsPowerShell\password.txt' | ConvertTo-SecureString
$Credentials = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password

#powercli
function PowerCLI {
    param([switch] $SaveCreds)
    if ($SaveCreds) {
        connect-VIServer ndb-vmware.service.emory.edu,ws-vmware.service.emory.edu -Credential (Get-Credential EMORYUNIVAD\eusubmatt) -SaveCredentials
    } else {
        connect-VIServer ndb-vmware.service.emory.edu,ws-vmware.service.emory.edu
    }
    if ((Get-Host).UI.RawUI.WindowTitle -notlike "*PowerCLI*") {
        (Get-Host).UI.RawUI.WindowTitle += " w/PowerCLI"
    }
}

#What .net is a cmdlet calling on?
function Get-cmdletinfo () {
        param([Parameter(Mandatory)]$cmdlet)    
    
    (Get-Command $cmdlet) | Format-List Name,CommandType,DLL,ImplementingType
}

# Map to T:
$CheckForT = Get-PSDrive -Name "T" -ErrorAction SilentlyContinue
if (!$CheckForT) {
New-PSDrive -Name "T" -PSProvider "FileSystem" -Root "\\eu.emory.edu\SystemsTeam"
}

#Import Rob's Modules
Import-Module "T:\Code\Modules\ENTSystems"

#Connect to VMServers
connect-VIServer ndb-vmware.service.emory.edu, ws-vmware.service.emory.edu -Credential $Credentials

#Touch
set-alias "touch" New-Item

##What time is it?
function Get-Time { return $(get-date -Format g) }
function prompt
{
    # Write the time 
    write-host "[" -noNewLine
    write-host $(Get-Time) -foreground yellow -noNewLine
    write-host "] " -noNewLine
    # Write the path
    write-host $($(Get-Location).Path.replace($home,"~")) -foreground green -noNewLine
    write-host $(if ($nestedpromptlevel -ge 1) { '>>' }) -noNewLine
    return "> "
}



##Transcript of session
Write-Verbose ("[{0}] Initialize Transcript" -f (Get-Date).ToString()) -Verbose

$transcripts = (Join-Path $Env:USERPROFILE "Documents\WindowsPowerShell\Transcripts")

    $global:TRANSCRIPT = ("{0}\PSLOG_{1:dd-MM-yyyy}.txt" -f $transcripts,(Get-Date))

    Start-Transcript -Path $transcript -Append

    Get-ChildItem $transcripts | Where {

        $_.LastWriteTime -lt (Get-Date).AddDays(-14)

    } | Remove-Item -Force -ea 0

Clear-Host