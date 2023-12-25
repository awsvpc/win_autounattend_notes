$ComputerName = "caroot"
$CACommonName = "Parithon Labs Root Certificate 01"
$DomainNamingContext = "DC=conradscloud,DC=com"
$ISOPath = "C:\Users\anthonyconrad\Downloads\en-us_windows_server_2019_updated_aug_2021_x64_dvd_a6431a28.iso"
$VirtualHardDiskPath = "C:\Users\Public\Documents\Hyper-V\Virtual Hard Disks"
$VirtualMachinePath = "C:\ProgramData\Microsoft\Windows\Hyper-V"
$UnattendPath = "C:\dev\unattendServerFull.xml"
$AdminPass = "mslabs.1"
$CACertUrl = "http://www.conradscloud.com/pki"
$CAPolicy = @'
[Version]
Signature="$Windows NT$"
[certsrv_server]
RenewalKeyLength=4096
RenewalValidityPeriod=Years
RenewalValidityPeriodUnits=30
CRLPeriod=Months
CRLPeriodUnits=6
CRLDeltaPeriod=Days
CRLDeltaPeriodUnits=0
[BasicConstraintsExtension]
PathLength=2
Critical=Yes
'@

function Test-PSHostHasAdministrator {
  $p = New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())
  if ($p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
      return $true
  }
  return $false
}
function Restart-Computer {
  $Process = Get-Process -Id $PID
  $value = $Process.Path + " -NoExit -File `"$PSCommandPath`""
  $params = $script:PSBoundParameters
  foreach ($key in $params.Keys) {
    if ($params[$key] -is [string]) {
      $value += " -$key `"$($params[$key])`""
    }
    else {
      $value += " -$key $($params[$key])"
    }
  }
  New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce" -Name "!CARootInstall" -Value $value -Force | Out-Null
  Write-Verbose "Restarting in 5 seconds... Press CTRL+C to cancel"
  Start-Sleep -Seconds 5
  Microsoft.PowerShell.Management\Restart-Computer -Force
}

# if ($env:HOSTNAME -ne "$ComputerName-Host") {
#   Write-Verbose "Renaming '$env:HOSTNAME' to '$ComputerName-Host'..."
#   Rename-Computer -NewName "$ComputerName-Host" -Restart
#   return
# }

if (-not (Get-WindowsOptionalFeature -FeatureName 'Microsoft-Hyper-V-All' -Online).State -eq 'Enabled') {
  Write-Verbose "Installing Hyper-V feature..."
  Enable-WindowsOptionalFeature -FeatureName 'Microsoft-Hyper-V-All' -Online -Restart -ErrorAction Stop
  Restart-Computer -Force
  return
}

Import-Module Hyper-V

if (-not (Get-VMHost).VirtualHardDiskPath -ne $VirtualHardDiskPath) {
  Write-Verbose "Configuring Hyper-V Host Settings"
  Set-VMHost -VirtualHardDiskPath $VirtualHardDiskPath -VirtualMachinePath $VirtualMachinePath -EnableEnhancedSessionMode $true
}

if (-not (Test-Path "$VirtualHardDiskPath\$ComputerName-os.vhdx")) {
  Write-Verbose "Installing Operating System for '$ComputerName'"
  
  $hdpath = (New-VHD -Path "$VirtualHardDiskPath\$ComputerName-os.vhdx" -SizeBytes 120GB -Dynamic).Path
  $vhd = Mount-DiskImage -ImagePath $hdpath -StorageType VHDX -Access ReadWrite
  $disk = Get-Disk $vhd.Number
  if (-not ($disk.PartitionStyle -eq 'GPT')) {
    $disk | Initialize-Disk -PartitionStyle GPT
    $disk | Remove-Partition -PartitionNumber 1 -Confirm:$false
    $disk | New-Partition -Size 499MB -GptType '{de94bba4-06d1-4d40-a16a-bfd50179d6ac}' | Out-Null
    $efipart = $disk | New-Partition -Size 99MB -GptType '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}' -AssignDriveLetter
    $disk | New-Partition -Size 16MB -GptType '{e3c9e316-0b5c-4db8-817d-f92df00215ae}' | Out-Null
    $datapart = $disk | New-Partition -GptType '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}' -UseMaximumSize -AssignDriveLetter
    Format-Volume -Partition $efipart -FileSystem FAT32 -NewFileSystemLabel "SYSTEM" | Out-Null
    $volume = Format-Volume -Partition $datapart -FileSystem NTFS -NewFileSystemLabel "OS"
  } else {
    $datapart = $disk | Get-Partition -PartitionNumber 3
    $volume = Get-Volume -Partition $datapart
  }

  # Apply windows image to OS partition, if needed
  if (-not (Test-Path "$($volume.DriveLetter):\Windows")) {
    $cdrom = Mount-DiskImage -ImagePath $ISOPath -StorageType ISO -Access ReadOnly -PassThru
    Write-Host "Choose an image to install:" -ForegroundColor $Host.PrivateData.WarningForegroundColor
    $imagePath = "$((Get-Volume -DiskImage $cdrom).DriveLetter):\sources\install.wim"
    Get-WindowsImage -ImagePath $imagePath | Select-Object ImageIndex,ImageName | ForEach-Object {
      Write-Host "$($_.ImageIndex): $($_.ImageName)"
    }
    Expand-WindowsImage -Index (Read-Host -Prompt "Index") -ImagePath $imagePath -ApplyPath "$($volume.DriveLetter):\" | Out-Null
    Dismount-DiskImage -ImagePath $ISOPath | Out-Null
  }

  $bcdparams = @(
    "$($datapart.DriveLetter):\Windows",
    "/s $($efipart.DriveLetter):\",
    "/f UEFI"
  )

  Start-Process -FilePath "bcdboot.exe" -ArgumentList $bcdparams -NoNewWindow -Wait
  $efipart | Remove-PartitionAccessPath -AccessPath $efipart.AccessPaths[0]

  (Get-Content -Path $UnattendPath -Raw) -replace "<ComputerName>\*<\/ComputerName>","<ComputerName>$ComputerName</ComputerName>" -replace "P@ssw0rd",$AdminPass | Out-File "$($datapart.DriveLetter):\unattend.xml" -Force

  Dismount-DiskImage -ImagePath $hdpath | Out-Null
}

if (-not ($vm = Get-VM $ComputerName -ErrorAction Ignore))
{
  Write-Verbose "Creating virtual machine '$ComputerName'"
  $vm = New-VM -Name $ComputerName -MemoryStartupBytes 4GB -VHDPath "$VirtualHardDiskPath\$ComputerName-os.vhdx" -Generation 2
}

if (-not ($vm.ProcessorCount -gt 1)) {
  Write-Verbose "Configuring virtual machine '$ComputerName'"
  Set-VM -VM $vm -AutomaticStartAction Nothing -AutomaticStopAction Save -BatteryPassthroughEnabled $true -ProcessorCount 2 -CheckpointType Disabled -EnhancedSessionTransportType VMBus -ErrorAction Stop
  Set-VMFirmware -VM $vm -EnableSecureBoot On -ErrorAction Stop
  Set-VMKeyProtector -VM $vm -NewLocalKeyProtector -ErrorAction Stop
  Enable-VMTPM -VM $vm -ErrorAction Stop
  Set-VMSecurity -VM $vm -EncryptStateAndVmMigrationTraffic $true -ErrorAction Stop
  Set-VMSecurityPolicy -VM $vm -Shielded $true -ErrorAction Stop
}

if (-not ($vm.State -eq 'Running')) {
  Write-Verbose "Staring virtual machine '$ComputerName'"
  Start-VM -VM $vm
  Wait-VM -VM $vm -For MemoryOperations
}

if (-not ($vm.Notes -like "*ADCS Installed*")) {
  Write-Verbose "Installing and configuring ADCS on '$ComputerName'"
  $session = New-PSSession -VMId $vm.Id -Credential (New-Object PSCredential Administrator, (ConvertTo-SecureString -AsPlainText -Force $AdminPass)) -ErrorAction Stop
  Invoke-Command -Session $session {
    if (-not (Get-WindowsFeature ADCS-Cert-Authority).Installed -eq $true) {
      Remove-Item "C:\unattend.xml" -Force
      Add-WindowsFeature ADCS-Cert-Authority -IncludeManagementTools
      $using:CAPolicy | Out-File "C:\Windows\CAPolicy.inf" -Encoding ascii -Force
      Install-AdcsCertificationAuthority -CACommonName $using:CACommonName -CAType StandaloneRootCA -KeyLength 4096 -ValidityPeriod Years -ValidityPeriodUnits 30 -Force
      certutil.exe -setreg CA\DSConfigDN "CN=Configuration,$using:DomainNamingContext"
      certutil.exe -setreg CA\CRLPublicationURLs ("1:$env:WINDIR\system32\CertSrv\CertEnroll\%3%8%9.crl\n2:http://$using:CACertUrl/certenroll/%3%8%9.crl\n10:ldap:///CN=%7%8,CN=%2,CN=CDP,CN=Public Key Services,CN=Services,%6%10")
      certutil.exe -setreg CA\CACertPublicationURLs ("1:$env:WINDIR\system32\CertSrv\CertEnroll\%3%4.crt\n2:http://$using:CACertUrl/certenroll/%3%4.crt\n2:ldap:///CN=%7,CN=AIA,CN=Public Key Services,CN=Services,%6%11")
      certutil.exe -setreg CA\ValidityPeriodUnits Years
      certutil.exe -setreg CA\ValidityPeriod 15
      certutil.exe -setreg CA\AuditFilter 127
      Restart-Service CertSvc
      certutil.exe -CRL
    }
  }
  $session | Remove-PSSession
  Set-VM -VM $vm -Notes $($vm).Notes + "ADCS Installed`n"
}
