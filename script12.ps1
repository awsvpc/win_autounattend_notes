# IC Server Installation
#
#

<# # Documentation {{{
  .Synopsis
  Installs CIC
#> # }}}
[CmdletBinding()]
Param(
  [Parameter(Mandatory=$false)][string] $User               = 'vagrant',
  [Parameter(Mandatory=$false)][string] $Password           = 'vagrant',
  # Note: This is different!!!!
  #[Parameter(Mandatory=$false)][string] $InstallPath        = 'C:\I3\IC',
  [Parameter(Mandatory=$false)][string] $InstallSource        = 'C:\',
  [Parameter(Mandatory=$false)][string]  $SourceDriveLetter = 'I',
  [Parameter(Mandatory=$false)][switch] $Wait,
  [Parameter(Mandatory=$false)][switch] $Reboot
)
Write-Output "Script started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$Now = Get-Date -Format 'yyyyMMddHHmmss'

#$Source_filename       = "ICServer_2015_R2.msi"
$Source_filename       = "7zip.msi"

$Product = 'Interaction Center Server 2015 R2'
if (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object DisplayName -eq $Product)
{
  Write-Output "$Product is already installed"
}
else
{
  Write-Output "Installing $Product"
  $stop_watch = [Diagnostics.StopWatch]::StartNew()

  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.UseShellExecute = $false
  $psi.FileName = 'msiexec'

  if ([Environment]::OSVersion.Version -ge (New-Object 'Version'6,0)) { $psi.Verb = "runas" }
  $psi.WorkingDirectory = "C:\Windows\Temp"
  $psi.Arguments = "/i `"${InstallSource}\${Source_filename}`" /qn /norestart REBOOT=ReallySuppress /l*v `"C:\Windows\Logs\icserver-${Now}.log`""
   Write-Output "Arguments: [$($psi.Arguments)]"

   Write-Output "Starting process"
   $result = [System.Diagnostics.Process]::Start($psi)
   Write-Output "process started"
   Write-Output "waiting for process to exit"
   while (! $result.WaitForExit(60000))
   {
     $elapsed = ''
     if ($stop_watch.Elapsed.Days    -gt 0) { $elapsed = " $($stop_watch.Elapsed.Days) days" }
     if ($stop_watch.Elapsed.Hours   -gt 0) { $elapsed = " $($stop_watch.Elapsed.Hours) hours" }
     if ($stop_watch.Elapsed.Minutes -gt 0) { $elapsed = " $($stop_watch.Elapsed.Minutes) minutes" }
     if ($stop_watch.Elapsed.Seconds -gt 0) { $elapsed = " $($stop_watch.Elapsed.Seconds) seconds" }
     Write-Output "$Product is still installing after $elapsed"
   }
   $stop_watch.Stop()

   $elapsed = ''
   if ($stop_watch.Elapsed.Days    -gt 0) { $elapsed = " $($stop_watch.Elapsed.Days) days" }
   if ($stop_watch.Elapsed.Hours   -gt 0) { $elapsed = " $($stop_watch.Elapsed.Hours) hours" }
   if ($stop_watch.Elapsed.Minutes -gt 0) { $elapsed = " $($stop_watch.Elapsed.Minutes) minutes" }
   if ($stop_watch.Elapsed.Seconds -gt 0) { $elapsed = " $($stop_watch.Elapsed.Seconds) seconds" }
   Write-Output "$Product installed successfully in $elapsed (Exit: $($result.ExitCode))"
   if ($result.ExitCode -ge 0)
   {
     Write-Output "Check the VM!"
     Start-Sleep 900
   }
   exit $result.ExitCode
}
