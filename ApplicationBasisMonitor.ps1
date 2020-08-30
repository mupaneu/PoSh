# ApplicationBasisMonitor.ps1. Monitoring activity status of an application: host ping, check log write, check output. To be run from distant host. Audience: Informed IT basis.
# A Scheduled Task trigger interval, if you want unattended runs, should adapt to the timespan here.



#region Literals
[string]$strApplicationHostIP = "192.168.0.0"
[string]$strApplicationLog = "\\server\share\Log"
[string]$strApplicationOutput = "\\server\share\output"
[string]$strTransferShare = "\\server2\share\"
# [int]$intInterval = 2 # hours

[string]$strSmtp = "smtp.org.org"
[string[]]$strMailTo = "me@org.org", "servicedesk@org.org"
[string]$strMailFrom = "me@org.org"
[string]$strMailSubject = "Org: Application: Basis monitor alert."
#endregion


#region Body
[boolean]$blnSuccess = $True

$objResults = New-Object PSObject
$objResults | Add-Member "Test time" (Get-Date).ToString()
$objResults | Add-Member "HostPing" (Test-Connection $strApplicationHostIP)

if (Test-Connection -Quiet -Count 1 $strApplicationHostIP)
{
    $objResults | Add-Member "Ping" "OK"
}

else
{
    $objResults | Add-Member "Ping" "Failed"
    $blnSuccess = $false
}


[DateTime]$datLastLogWrite = (dir $strApplicationLog | Sort-Object LastWriteTime -Descending | select -First 1).LastWriteTime
$objResults | Add-Member "LastLogWrite" $datLastLogWrite

if ((get-date).AddHours(-2) -gt $datLastLogWrite)
{
    $objResults | Add-Member "Log" "no write for 2 hours"
    $blnSuccess = $false
}

else
{
    $objResults | Add-Member "Log" "Active in last 2 hours"
}


[DateTime]$datLastOutputWrite = (dir $strApplicationOutput | Sort-Object LastWriteTime -Descending | select -First 1).LastWriteTime
$objResults | Add-Member "LastOutputWrite" $datLastOutputWrite


if ((get-date).AddHours(-2) -gt $datLastOutputWrite)
{
    $objResults | Add-Member "Output" "no write for 2 hours"
    $blnSuccess = $false
}

else
{
    $objResults | Add-Member "Output" "Active in last 2 hours"
}


[DateTime]$datLastTransferWrite = (dir $strTransferShare -Recurse | Sort-Object LastWriteTime -Descending | select -First 1).LastWriteTime
$objResults | Add-Member "LastTransferWrite" $datLastTransferWrite


if ((get-date).AddHours(-2) -gt $datLastTransferWrite)
{
    $objResults | Add-Member "Transfer" "no write for 2 hours"
    $blnSuccess = $false
}

else
{
    $objResults | Add-Member "Transfer" "Active in last 2 hours"
}

if ($blnSuccess -eq $false)
{
    $strMailSubject = "Application inactive? " + $strMailSubject
}

    Send-MailMessage -SmtpServer $strSmtp `
    -From $strMailFrom `
    -Subject $strMailSubject `
    -body ($objResults | Out-String) `
    -To $strMailTo

#endregion
