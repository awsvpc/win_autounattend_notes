<powershell>

write-output "Running User Data Script"
write-host "(host) Running User Data Script"

Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force -ErrorAction Ignore

# Don't set this before Set-ExecutionPolicy as it throws an error
$ErrorActionPreference = "stop"

$NLMType = [Type]::GetTypeFromCLSID('DCB00C01-570F-4A9B-8D69-199FDBA5723B')
$INetworkListManager = [Activator]::CreateInstance($NLMType)
$NLM_ENUM_NETWORK_CONNECTED = 1
$NLM_NETWORK_CATEGORY_PUBLIC = 0x00
$NLM_NETWORK_CATEGORY_PRIVATE = 0x01
$INetworks = $INetworkListManager.GetNetworks($NLM_ENUM_NETWORK_CONNECTED)

do{
  sleep 1
  $INetworks = $INetworkListManager.GetNetworks($NLM_ENUM_NETWORK_CONNECTED)
}until(($INetworks | measure).count -gt 0)

foreach ($INetwork in $INetworks) {
  $INetwork.SetCategory($NLM_NETWORK_CATEGORY_PRIVATE)
}

stop-service winrm
winrm quickconfig -q
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="4096"}'
winrm set winrm/config '@{MaxTimeoutms="1800000"}'
winrm set winrm/config/client '@{AllowUnencrypted="true"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
netsh advfirewall firewall add rule `
  name="Enable WinRM" dir=in action=allow protocol=TCP `
  localport=5985
start-service winrm

</powershell>