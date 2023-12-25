$ComputerName = "New Name"
   
Remove-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -name "Hostname" 
Remove-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -name "NV Hostname" 

Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Control\Computername\Computername" -name "Computername" -value $ComputerName
Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Control\Computername\ActiveComputername" -name "Computername" -value $ComputerName
Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -name "Hostname" -value $ComputerName
Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -name "NV Hostname" -value  $ComputerName
Set-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -name "AltDefaultDomainName" -value $ComputerName
Set-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -name "DefaultDomainName" -value $ComputerName
======================================

SET /P < ipaddress >
REG ADD HKLM\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName /v ComputerName /t REG_SZ /d %PCNAME% /f

======================================

@echo off

set "cName=ROG-ISRA"
set "OEM=ROG STRIX B650E-F GAMING WIFI"

REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation" /t REG_SZ /v Model /d "%OEM%" /f

wmic computersystem where name="%computername%" call rename name="%cName%"

REG ADD "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "Hostname" /d %cName% /f
REG ADD "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "NV Hostname" /d  %cName% /f

set "sysSets=SystemSettings.exe"

tasklist /fi "ImageName eq %sysSets%" /fo csv 2>NUL | find /I "%sysSets%">NUL
if "%ERRORLEVEL%"=="0" (
	taskkill /F /IM %sysSets% 
	start ms-settings:
)

======================================
