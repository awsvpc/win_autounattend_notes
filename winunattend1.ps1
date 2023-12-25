@'
<?xml version="1.0" encoding="utf-8"?>
<unattend
	xmlns="urn:schemas-microsoft-com:unattend">
	<settings pass="generalize">
		<component name="Microsoft-Windows-PnpSysprep" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"
			xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
			xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<PersistAllDeviceInstalls>true</PersistAllDeviceInstalls>
		</component>
	</settings>
	<settings pass="oobeSystem">
		<component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"
			xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
			<OOBE>
				<HideEULAPage>true</HideEULAPage>
				<NetworkLocation>Work</NetworkLocation>
				<ProtectYourPC>1</ProtectYourPC>
				<SkipMachineOOBE>true</SkipMachineOOBE>
				<SkipUserOOBE>true</SkipUserOOBE>
			</OOBE>
		</component>
	</settings>
	<settings pass="specialize">
		
		<component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"
			xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
			xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                        <!-- Auto extend OS partition -->
			<ExtendOSPartition>
				<Extend>true</Extend>
			</ExtendOSPartition>
                        <!-- Run custom command -->
			<RunSynchronous>
				<RunSynchronousCommand wcm:action="add">
					<Order>1</Order>
					<Path>powershell.exe -ExecutionPolicy Bypass -File C:\prep.ps1</Path>
					<Description>Run custom command</Description>
					<WillReboot>OnRequest</WillReboot>
				</RunSynchronousCommand>
			</RunSynchronous>
		</component>
	</settings>
</unattend>
'@ | Out-File -Encoding utf8 'C:\Unattend.xml'

@'
function install_opensshd()
{
	Write-Output "Download OpenSSH.Server package"
        Invoke-WebRequest https://github.com/PowerShell/Win32-OpenSSH/releases/latest/download/OpenSSH-Win64.zip -OutFile $env:TEMP\OpenSSH-Win64-latest.zip
	Write-Output "Extract to Program Files"
	Expand-Archive $env:TEMP\OpenSSH-Win64-latest.zip 'C:\' -Force
	Write-Output "Run install-sshd.ps1"
	powershell.exe -ExecutionPolicy Bypass -File C:\OpenSSH-Win64\install-sshd.ps1
	Write-Output "Start the sshd service"
	Start-Service sshd
	Set-Service -Name sshd -StartupType 'Automatic'
	# Confirm the Firewall rule is configured. It should be created automatically by setup. Run the following to verify
	if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue | Select-Object Name, Enabled)) {
		Write-Output "Firewall Rule 'OpenSSH-Server-In-TCP' does not exist, creating it..."
		New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
	} else {
		Write-Output "Firewall rule 'OpenSSH-Server-In-TCP' has been created and exists."
	}
}
function install_rdp()
{
	Write-Output "Activate RDP"
	Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0
	Write-Output "Firewall Rule 'Remote Desktop'"
	Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
}
### MAIN ###
install_rdp
install_opensshd
'@ | Out-File -Encoding utf8 'C:\prep.ps1'

& c:\Windows\System32\Sysprep\sysprep.exe /generalize /oobe /unattend:C:\Unattend.xml
