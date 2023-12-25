New-ItemProperty -path "Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\JavaSoft\Java Update\Policy" -Name "EnableJavaUpdate" -PropertyType Dword -Value "0" -force
