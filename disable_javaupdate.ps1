New-ItemProperty -path "Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\JavaSoft\Java Update\Policy" -Name "EnableJavaUpdate" -PropertyType Dword -Value "0" -force



reg load HKU\DefaultProfile C:\Users\default\ntuser.dat
New-Item -path "Microsoft.PowerShell.Core\Registry::HKEY_USERS\DefaultProfile\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\"
New-Item -path "Microsoft.PowerShell.Core\Registry::HKEY_USERS\DefaultProfile\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"
New-ItemProperty -path "Microsoft.PowerShell.Core\Registry::HKEY_USERS\DefaultProfile\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -PropertyType Dword -Value "0" -force
#New-ItemProperty -path "Microsoft.PowerShell.Core\Registry::HKEY_USERS\DefaultProfile\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" -Name "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" -PropertyType Dword -Value "0" -force
#reg unload HKU\DefaultProfile
