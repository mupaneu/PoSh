# 20190319 Log4net-Monitor.ps1
# Sends a mail when a search term is logged in log4net logs. Can e.g. be run as a Scheduled Task. Logs hits to not repeatedly alert same log entries.
# Understand the script before you use it.

param (
    [string]$AppLogFile = "C:\temp\logs\server\app.log",
    [string]$SearchTerm = ".SQLException"
)

$Error.Clear()

[string]$strLogFile = $PSCommandPath + ".log"

$Body = $null

if ( (Test-Path $strLogFile) -eq $false )
    { Set-Content -Path $strLogFile -Value "LogMonitor`r`n_______________`r`n" }

[boolean]$blnNewEntries = $false

if ( (Test-Path $AppLogFile) -eq $false )
{
    Write-Error "No log file to parse, $AppLogFile was given."
}

else
{
    [string]$strAppLogFile = $AppLogFile + ".tmp"
    Copy-Item $AppLogFile $strAppLogFile
    [string[]]$astrLogContent = ([io.file]::ReadAllText($strAppLogFile)).Replace("`r`n   ","   ").Replace("`r`n([a-z,A-Z])"," $2") -split("`r`n") -match($SearchTerm)

    [string[]]$astrEntriesAlreadySent = Get-Content $strLogFile

    for ($i = 0;$i -lt $astrLogContent.count; $i++)
    {
        [string[]]$astrRow = $astrLogContent[$i].Split("\[")
        [string]$strTime = $astrRow[0].Trim()
        if ($strTime -in $astrEntriesAlreadySent -or $strTime -notlike '20*' )
        {
            $astrLogContent[$i] = "(Deleted)"
        }
        else
        {
            $blnNewEntries = $true
            Add-Content $strLogFile -Value $strTime
        }
    }

    switch ($blnNewEntries)
    {
        $true { [string]$Body = ($astrLogContent -notmatch("(Deleted)") | Sort-Object) -join("`r`n") }
        $false { [string]$Body = "No new entries for search term." }
    }
    
}

if ($error -ne $null)
{
    $Body += "`r`n`r`nErrors`r`n"
    $Body += ($Error | Select-Object *)
}

$Body += "`r`n`r`nLog entries sent`r`n___________`r`n"
[string[]]$astrParseLogSentWholeStory = Get-Content $strLogFile
$Body += ($astrParseLogSentWholeStory -match '20*') -join("`r`n")

if ($blnNewEntries -or ($Error -ne $null))
{
    Send-MailMessage -From me@org.org -To me@org.org -Body $Body -SmtpServer 191.100.2.55 -Subject "New $SearchTerm or script error on $env:COMPUTERNAME in $AppLogFile"
}
