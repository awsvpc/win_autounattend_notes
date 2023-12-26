<powershell>
winrm quickconfig -q
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="300"}'
winrm set winrm/config '@{MaxTimeoutms="1800000"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'

netsh advfirewall firewall add rule name="WinRM 5985" protocol=TCP dir=in localport=5985 action=allow
netsh advfirewall firewall add rule name="WinRM 5986" protocol=TCP dir=in localport=5986 action=allow

net stop winrm
Set-Service winrm -startuptype Automatic
net start winrm

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope LocalMachine
</powershell>
==============================

{
  "builders": [
  {
    "type": "amazon-ebs",
    "region": "us-east-1",
    "instance_type": "t2.medium",
    "source_ami_filter": {
			"filters": {
				"virtualization-type": "hvm",
				"name": "Windows_Server-2012-R2_RTM-English-64Bit-Base-*",
				"root-device-type": "ebs"
			},
			"most_recent": true
		},
    "ami_name": "BaseRestWindowsImage-{{isotime | clean_ami_name}}",
    "user_data_file": "userdata/windows-aws.txt",
    "communicator": "winrm",
    "winrm_username": "administrator",
    "winrm_use_ssl": false,
    "winrm_insecure": true,
    "winrm_timeout": "12h"
  }],
  "provisioners": [{
    "type": "powershell",
    "inline": [
      "dir c:\\"
    ]
  },
  {
      "type":  "ansible",
      "playbook_file": "./windows.yml",
      "extra_arguments": [
        "--connection", "packer", "-vvv",
        "--extra-vars", "ansible_shell_type=powershell ansible_shell_executable=None"
      ]
  }]
}
================================

$installerRepository = ''

$region = ''
$keyPrefix = ''

$localPath = ''

if (-Not (Test-Path -Path $localPath)){New-Item -Path $localPath -ItemType directory -Force | out-null}
$artifacts = Get-S3Object -BucketName $installerRepository -KeyPrefix $keyPrefix -Region $region
foreach($artifact in $artifacts) {$localFileName = $artifact.Key -replace $keyPrefix, '' 
if ($localFileName -ne '') {$localFilePath = Join-Path $localPath $localFileName 
Copy-S3Object -BucketName $installerRepository -Key $artifact.Key -LocalFile $localFilePath -Region $region}} 
