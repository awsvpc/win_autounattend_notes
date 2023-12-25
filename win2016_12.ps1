
$EC2SettingsFile="C:\\Program Files\\Amazon\\Ec2ConfigService\\Settings\\Config.xml"
$xml = [xml](get-content $EC2SettingsFile)
$xmlElement = $xml.get_DocumentElement()
$xmlElementToModify = $xmlElement.Plugins

foreach ($element in $xmlElementToModify.Plugin)
{
    if ($element.name -eq "Ec2SetPassword")
    {
        $element.State="Enabled"
    }
    elseif ($element.name -eq "Ec2SetComputerName")
    {
        $element.State="Enabled"
    }
    elseif ($element.name -eq "Ec2HandleUserData")
    {
        $element.State="Enabled"
    }
}
$xml.Save($EC2SettingsFile)

==========================

RefreshEnv

#open firewall
cmd.exe /c netsh advfirewall firewall add rule name='SSH Port' dir=in action=allow protocol=TCP localport=22

#start ssh server
cd "C:\Program Files\OpenSSH-Win64"
.\install-sshd.ps1
.\ssh-keygen.exe -A

cmd.exe /c sc config ssh-agent start= auto
cmd.exe /c sc config sshd start= auto
cmd.exe /c sc start sshd

=====================

<powershell>
write-output "Running User Data Script"
write-host "(host) Running User Data Script"

Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force -ErrorAction Ignore

# Don't set this before Set-ExecutionPolicy as it throws an error
$ErrorActionPreference = "stop"


# Remove HTTP listener

Remove-Item -Path WSMan:\Localhost\listener\listener* -Recurse

if ($PSVersionTable.PSVersion -ge [version]"4.0.0.0")
{
  $Cert = New-SelfSignedCertificate -CertstoreLocation Cert:\LocalMachine\My -DnsName "packer"
}
else
{
  $modulePath = Join-Path $Env:TEMP "New-SelfSignedCertificateEx.ps1"
  $moduleUrl = "https://gist.githubusercontent.com/phoewass/6d5f86b2c3b8d4b23c8ae2a44fa4e8ca/raw/882cb85115d95ef24659b8d1f5883efc13e0286e/New-SelfSignedCertificateEx.ps1"
  (New-Object System.Net.WebClient).DownloadFile($moduleUrl,$modulePath)
  Import-Module $modulePath
  $Cert = New-SelfSignedCertificateEx  -StoreLocation LocalMachine -Subject "CN=packer" -EKU "Server Authentication"
}

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

=================================

{
  "builders": [{
    "type": "amazon-ebs",
    "region": "us-east-1",
    "vpc_id": "",
    "subnet_id": "",
    "source_ami": "ami-50903a46",
    "instance_type": "t2.large",
    "ami_name": "windows-2008r2-ssh",
    "user_data_file": "scripts/userdata.ps1",
    "communicator": "winrm",
    "winrm_username": "Administrator",
    "winrm_timeout": "5m",
    "winrm_use_ssl": true,
    "winrm_insecure": true
    }],
  "provisioners": [
    {
      "type": "powershell",
      "inline": "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))"
    },
    {
      "type": "windows-shell",
      "inline": "choco install -y openssh"
    },
    {
      "type": "powershell",
      "scripts": [
        "scripts/configure.ps1",
        "scripts/provision.ps1"
      ]
    }
  ]
}

