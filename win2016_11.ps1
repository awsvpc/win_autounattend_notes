{
    "builders": [
        {
            "type": "amazon-ebs",
            "region": "us-west-2",
            "vpc_id": "redacted",
            "subnet_id": "redacted",
            "security_group_id": "redacted",
            "instance_type": "t2.large",
            "ami_name": "tester {{timestamp}}",
            "user_data_file": "SetUpWinRM.ps1",
            "communicator": "winrm",
            "winrm_username": "Administrator",
            "winrm_use_ssl": true,
            "winrm_insecure": true,
            "source_ami_filter": {
                "filters": {
                  "name": "Windows_Server-2016-English-Full-Base-*"
                },
                "owners": ["801119661308"],
                "most_recent": true
            }
        }
    ],
    "provisioners": [
        {
            "type": "powershell",
            "scripts": [
                "provisionapps.ps1"

            ]
        }
    ],
    "post-processors": [
        {
            "type": "manifest"
        }
    ]
}


=================================

# Install Chocolatey
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
# Globally Auto confirm every action
choco feature enable -n allowGlobalConfirmation

# Install .net 4.5.2
choco install netfx-4.5.2-devpack

# Install build tools 2015
choco install microsoft-build-tools --version 14.0.25420.1

choco install nuget.commandline
choco install nunit-console-runner
# Extension for generating results readable by Bamboo
choco install nunit-extension-nunit-v2-result-writer
choco install git
==============================

setup_winrm.ps1

<powershell>

write-output "Running User Data Script"
write-host "(host) Running User Data Script"

Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force -ErrorAction Ignore

# Don't set this before Set-ExecutionPolicy as it throws an error
$ErrorActionPreference = "stop"

# Remove HTTP listener
Remove-Item -Path WSMan:\Localhost\listener\listener* -Recurse

$Cert = New-SelfSignedCertificate -CertstoreLocation Cert:\LocalMachine\My -DnsName "packer"
New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $Cert.Thumbprint -Force

# WinRM
write-output "Setting up WinRM"
write-host "(host) setting up WinRM"

cmd.exe /c winrm quickconfig -q
cmd.exe /c winrm set "winrm/config" '@{MaxTimeoutms="1800000"}'
cmd.exe /c winrm set "winrm/config/winrs" '@{MaxMemoryPerShellMB="1024"}'
cmd.exe /c winrm set "winrm/config/service" '@{AllowUnencrypted="true"}'
cmd.exe /c winrm set "winrm/config/client" '@{AllowUnencrypted="true"}'
cmd.exe /c winrm set "winrm/config/service/auth" '@{Basic="true"}'
cmd.exe /c winrm set "winrm/config/client/auth" '@{Basic="true"}'
cmd.exe /c winrm set "winrm/config/service/auth" '@{CredSSP="true"}'
cmd.exe /c winrm set "winrm/config/listener?Address=*+Transport=HTTPS" "@{Port=`"5986`";Hostname=`"packer`";CertificateThumbprint=`"$($Cert.Thumbprint)`"}"
cmd.exe /c netsh advfirewall firewall set rule group="remote administration" new enable=yes
cmd.exe /c netsh firewall add portopening TCP 5986 "Port 5986"
cmd.exe /c net stop winrm
cmd.exe /c sc config winrm start= auto
cmd.exe /c net start winrm

</powershell>
