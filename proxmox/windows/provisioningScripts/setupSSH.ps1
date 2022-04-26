Write-Host "Setup SSH Server"
#Add-WindowsCapability -Online -Name OpenSSH.Server*
$OpenSSHClient = Get-WindowsCapability -Online | ? Name -like ‘OpenSSH.Server*’
Add-WindowsCapability -Online -Name $OpenSSHClient.Name
# Start the sshd service
Start-Service sshd

# OPTIONAL but recommended:
Set-Service -Name sshd -StartupType 'Automatic'

# Confirm the Firewall rule is configured. It should be created automatically by setup. Run the following to verify
if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue | Select-Object Name, Enabled)) {
    Write-Output "Firewall Rule 'OpenSSH-Server-In-TCP' does not exist, creating it..."
    New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
} else {
    Write-Output "Firewall rule 'OpenSSH-Server-In-TCP' has been created and exists."
}
$file = %programdata%/ssh/administrators_authorized_keys
New-Item $file -ItemType file

$content = Invoke-WebRequest https://github.com/qnlbnsl.keys -UseBasicParsing
$keys = $content.Content
Add-Content -Path $file -Value $keys 

