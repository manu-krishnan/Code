##Basic Startup
cd \

#powercli
function PowerCLI {
    param([switch] $SaveCreds)
    if ($SaveCreds) {
        connect-VIServer ndb-vmware.service.emory.edu,ws-vmware.service.emory.edu `
         -Credential (Get-Credential EMORYUNIVAD\eusubmatt) -SaveCredentials
    } else {
        connect-VIServer ndb-vmware.service.emory.edu,ws-vmware.service.emory.edu
    }
    if ((Get-Host).UI.RawUI.WindowTitle -notlike "*PowerCLI*") {
        (Get-Host).UI.RawUI.WindowTitle += " w/PowerCLI"
    }
}

#Import Rob's Modules
Import-Module "T:\Code\Modules\ENTSystems"

#Credentials
$ComputerName = ""
$Username = "emoryunivad\eusubmatt"
$Password = Get-Content 'C:\Users\eusubmatt\Documents\WindowsPowerShell\password.txt' | ConvertTo-SecureString
$Credentials = new-object -typename System.Management.Automation.PSCredential `
         -argumentlist $username, $password

# Map to T:
New-PSDrive -Name "T" -PSProvider "FileSystem" -Root "\\eu.emory.edu\SystemsTeam"

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

##Where is it? 
function Locate-File{
param([string]$file)
$objs = Get-ChildItem -Recurse -Filter $file -ErrorAction SilentlyContinue -Path C:\
$objs.FullName
}

## List Everything in a directory
function list { ls -force }


# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
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