# Reset-LocalAccountPassword.ps1
# Written by Bill Stewart (bstewart@iname.com)

#requires -version 2

<#
.SYNOPSIS
Resets the built-in Administrator account or a named local account password on one or more computers.

.DESCRIPTION
Resets the built-in Administrator account or a named local account password on one or more computers. The Administrator account is determined by its RID (500), not its name.

.PARAMETER ComputerName
Specifies one or more computer names. The default is the current computer. Wildcards are not permitted.

.PARAMETER AccountName
Specifies that you want to reset the password for the specified local account.

.PARAMETER AdminAccount
Specifies that you want to reset the password for the built-in Administrator account.

.PARAMETER Password
Specifes the new password for the account. If you omit this parameter (recommended), you will be prompted to enter the new password twice (for confirmation).

.PARAMETER Credential
Specifies credentials that have permission to reset the password on the computer(s). If you omit this parameter, the current logon account must have permission to reset the password.

.EXAMPLE
PS C:\> Reset-LocalAccountPassword -AdminAccount
This command will reset the built-in Administrator password on the current computer.

.EXAMPLE
PS C:\> Reset-LocalAccountPassword COMPUTER1,COMPUTER2 -AdminAccount -Confirm:$false
This command will reset the built-in Administrator password on two different computers without prompting for confirmation.

.EXAMPLE
PS C:\> Reset-LocalAccountPassword -AccountName Manager
This command will reset the password for the local account named 'Manager' on the current computer.

.EXAMPLE
PS C:\> Reset-LocalAccountPassword PC3,PC4 -AccountName Supervisor -Confirm:$false
This command will reset the password of the local account named 'Supervisor' on two different computers without prompting for confirmation.

.EXAMPLE
PS C:\> Get-Content Computers.txt | Reset-LocalAccountPassword -AdminAccount -Confirm:$false
This command will reset the built-in Administrator password for the computers named in the file Computers.txt without prompting for confirmation.

.EXAMPLE
PS C:\> "WG1","WG2" | Reset-LocalAccountPassword -AdminAccount -Credential (Get-Credential)
This command will prompt to reset the built-in Administrator passwords on two computers. Before the command runs, it will prompt for credentials that have permission to reset the passwords.
#>

[CmdletBinding(DefaultParameterSetName="NamedAccount",SupportsShouldProcess=$true,ConfirmImpact="High")]
param(
  [Parameter(ParameterSetName="AdminAccount",Position=0,ValueFromPipeline=$true)]
  [Parameter(ParameterSetName="NamedAccount",Position=0,ValueFromPipeline=$true)]
    [String[]] $ComputerName=[Net.Dns]::GetHostName(),
  [Parameter(ParameterSetName="NamedAccount",Mandatory=$true)]
    [String] $AccountName,
  [Parameter(ParameterSetName="AdminAccount",Mandatory=$true)]
    [Switch] $AdminAccount,
  [Parameter(ParameterSetName="AdminAccount")]
  [Parameter(ParameterSetName="NamedAccount")]
    [Security.SecureString] $Password,
  [Parameter(ParameterSetName="AdminAccount")]
  [Parameter(ParameterSetName="NamedAccount")]
    [Management.Automation.PSCredential] $Credential
)

begin {
  $ScriptName = $MyInvocation.MyCommand.Name

  # Reset password for built-in Administrator account, not a named account.
  $AdminAccount = $PSCmdlet.ParameterSetName -eq "AdminAccount"

  # Safely compares two SecureString objects without decrypting them. Returns
  # $true if they are equal, or $false otherwise.
  function Compare-SecureString {
    param(
      [Security.SecureString] $secureString1,
      [Security.SecureString] $secureString2
    )
    try {
      $bstr1 = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString1)
      $bstr2 = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString2)
      $length1 = [Runtime.InteropServices.Marshal]::ReadInt32($bstr1, -4)
      $length2 = [Runtime.InteropServices.Marshal]::ReadInt32($bstr2, -4)
      if ( $length1 -ne $length2 ) {
        return $false
      }
      for ( $i = 0; $i -lt $length1; ++$i ) {
        $b1 = [Runtime.InteropServices.Marshal]::ReadByte($bstr1, $i)
        $b2 = [Runtime.InteropServices.Marshal]::ReadByte($bstr2, $i)
        if ( $b1 -ne $b2 ) {
          return $false
        }
      }
      return $true
    }
    finally {
      if ( $bstr1 -ne [IntPtr]::Zero ) {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr1)
      }
      if ( $bstr2 -ne [IntPtr]::Zero ) {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr2)
      }
    }
  }

  # Reads two SecureString objects (passwords), securely compares them, and
  # returns the confirmed password.
  function Read-PasswordWithConfirmation {
    if ( $AdminAccount ) {
      $name = "built-in Administrator account"
    }
    else {
      $name = "local account '$AccountName'"
    }
    do {
      $pass1 = Read-Host -Prompt ("Enter new password for {0}" -f $name) -AsSecureString
      $pass2 = Read-Host -Prompt ("Confirm new password for {0}" -f $name) -AsSecureString
      $equal = Compare-SecureString $pass1 $pass2
      if ( -not $equal ) {
        Write-Host "Passwords do not match"
      }
    } until ( $equal )
    return $pass1
  }

  # Decrypts and returns a SecureString as a String. Required for the
  # DirectoryEntry constructor and SetPassword methods because these API calls
  # use clear-text passwords. Even though the clear-text passwords will be
  # temporarily available in local memory, Windows does not send clear-text
  # passwords over the network.
  function ConvertTo-String {
    param(
      [Security.SecureString] $secureString
    )
    try {
      $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
      return [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    }
    finally {
      if ( $bstr -ne [IntPtr]::Zero ) {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
      }
    }
  }

  # Writes a custom error to the error stream.
  function Write-CustomError {
    param(
      [Exception] $exception,
      $targetObject,
      [String] $errorID,
      [Management.Automation.ErrorCategory] $errorCategory="NotSpecified"
    )
    $errorRecord = New-Object Management.Automation.ErrorRecord($exception,$errorID,$errorCategory,$targetObject)
    $PSCmdlet.WriteError($errorRecord)
  }

  # If the -Password parameter is not present, read it interactively.
  if ( -not $Password ) {
    $Password = Read-PasswordWithConfirmation
  }

  # Set up the process action string.
  if ( $AdminAccount ) {
    $ProcessAction = "Reset password for built-in Administrator account"
  }
  else {
    $ProcessAction = "Reset password for local account '$AccountName'"
  }

  # Called from script's process block: Resets the requested local account
  # password (either built-in Administrator account or a named account).
  function Reset-LocalAccountPassword {
    [CmdletBinding(ConfirmImpact="High")]
    param(
      [Parameter(ValueFromPipeline=$true)]
        [String[]] $computerName
    )
    process {
      $computerAdsPath = "WinNT://$computerName,Computer"
      if ( -not $Credential ) {
        $computer = [ADSI] $computerAdsPath
      }
      else {
        $computer = New-Object DirectoryServices.DirectoryEntry($computerAdsPath,$Credential.UserName,(ConvertTo-String $Credential.Password))
      }
      try {
        # Piping to Format-List forces PowerShell to connect to the computer
        # (we're only interested in a possible exception).
        [Void] ($computer | Format-List)
      }
      catch {
        $message = "Unable to connect to computer '$computerName' due to the following error: '{0}'" -f ($_.Exception.InnerException.Message -replace '\n+$', '')
        $exception = New-Object ($_.Exception.GetType().FullName)($message,$_.Exception)
        Write-CustomError $exception $computerName $ScriptName
        return
      }
      $localUser = $null
      $localUserName = ""
      $dirEntries = $computer.Children
      if ( $AdminAccount ) {
        try {
          foreach ( $childObject in $dirEntries ) {
            if ( $childObject.Class -eq "User" ) {
              $childObjectSID = New-Object Security.Principal.SecurityIdentifier($childObject.objectSid[0],0)
              if ( $childObjectSID.Value.EndsWith("-500") ) {
                $localUser = $childObject
                break
              }
            }
          }
        }
        catch {
          $message = "Unable to connect to computer '$computerName' due to the following error: '{0}'" -f ($_.Exception.InnerException.Message -replace '\n+$', '')
          $exception = New-Object ($_.Exception.GetType().FullName)($message,$_.Exception)
          Write-CustomError $exception $computerName $ScriptName
          return
        }
      }
      else {
        try {
          $localUser = $dirEntries.Find($AccountName, "User")
        }
        catch [Management.Automation.MethodInvocationException] {
          $message = "Unable to perform operation `"$ProcessAction`" on target `"$computerName`" due to the following error: '{0}'" -f ($_.Exception.InnerException.Message -replace '\n+$', '')
          $exception = New-Object ($_.Exception.GetType().FullName)($message,$_.Exception)
          Write-CustomError $exception $computerName $ScriptName
          return
        }
      }
      $localUserName = $localUser.Name[0]
      try {
        $localUser.SetPassword((ConvertTo-String $Password))
      }
      catch [Management.Automation.MethodInvocationException] {
        $message = "Unable to perform operation `"$ProcessAction`" on target `"$computerName`" due to the following error: '{0}'" -f ($_.Exception.InnerException.Message -replace '\n+$', '')
        $exception = New-Object ($_.Exception.GetType().FullName)($message,$_.Exception.InnerException)
        Write-CustomError $exception $computerName $ScriptName
      }
    }
  }
}

process {
  foreach ( $computerNameItem in $ComputerName ) {
    if ( $PSCmdlet.ShouldProcess($computerNameItem, $ProcessAction) ) {
      Reset-LocalAccountPassword $computerNameItem
    }
  }
}
