# Monitor-hosts.ps1. Best run as Scheduled Task at machine startup and repeated every 15 min.
# Is intended to detect changes even when you have not been online when your hosts has been tampered with.
# Do not run if you don't understand it.
# ex.: <Command>C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe</Command>
#      <Arguments>-NoExit -NoProfile -ExecutionPolicy ByPass -File C:\util\Monitor-hosts.ps1</Arguments>


[string]$strHostsLastPath = "c:\util\hosts.$env:COMPUTERNAME.last.xml"

# Ensure directory for hash store file
if ( ( Test-Path (Split-Path $strHostsLastPath -Parent) ) -eq $false )
{
    mkdir (Split-Path $strHostsLastPath -Parent)
}


if ( (Test-Path $strHostsLastPath) -eq $false ) # (Re) Initialize hash store file
{
    (Get-FileHash C:\Windows\System32\drivers\etc\hosts -Algorithm SHA512).ToString() | Export-Clixml $strHostsLastPath
    Set-ItemProperty $strHostsLastPath -Name IsReadOnly -Value $true
}

else # compare stored hash with current
{
        [string]$strHashNow = (Get-FileHash C:\Windows\System32\drivers\etc\hosts -Algorithm SHA512).ToString()
        [xml]$xmlHashLast = gc $strHostsLastPath
        if ($xmlHashLast.Objs.S -ne $strHashNow)
        {
            Add-Type -AssemblyName System.Windows.Forms
            [string]$strMsg = "Check hosts, if you haven't edited hosts yourself in the last 15 min. Most likely hosts' hash has changed. If so, delete $strHostsLastPath (read-only) to reset this monitor."
            [string]$strTitle = "hosts monitor"
            $void = [System.Windows.Forms.MessageBox]::Show($strMsg,$strTitle,[System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Exclamation)
        }
        else
        {
            "Hashs ident"
        }
}
