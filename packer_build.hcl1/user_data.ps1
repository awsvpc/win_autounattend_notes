#ps1_sysnative
cmd /C 'wmic UserAccount where Name="opc" set PasswordExpires=False'
$opcUser = get-wmiobject win32_useraccount | Where-Object { $_.Name -match 'opc' }
([adsi]("WinNT://"+$opcUser.caption).replace("\","/")).SetPassword("myPa55_Word")


winrm quickconfig
Enable-PSRemoting
winrm set winrm/config/client/auth '@{Basic="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="300"}'
winrm set winrm/config '@{MaxTimeoutms="1800000"}'
netsh advfirewall firewall add rule name="WinRM HTTP" protocol=TCP dir=in profile=any localport=5985 remoteip=any localip=any action=allow
netsh advfirewall firewall add rule name="WinRM HTTPS" protocol=TCP dir=in profile=any localport=5986 remoteip=any localip=any action=allow
net stop winrm
sc.exe config winrm start=auto
net start winrm