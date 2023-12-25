[cmdletbinding()]
param(
    [switch]$SkipAtlas,
    [Parameter(Mandatory=$true)]
    [ValidateSet("Win2012R2", "Win2016StdCore")]
    $OSName
)

switch ($OSName)
{
    'Win2012R2' {
        $osData = @{
            os_name = 'win2012r2'
            guest_os_type = 'Windows2012_64'
            full_os_name = 'Windows2012R2'
            iso_checksum = '849734f37346385dac2c101e4aacba4626bb141c'
            iso_url = 'http://care.dlservice.microsoft.com/dl/download/6/2/A/62A76ABB-9990-4EFC-A4FE-C7D698DAEB96/9600.17050.WINBLUE_REFRESH.140317-1640_X64FRE_SERVER_EVAL_EN-US-IR3_SSS_X64FREE_EN-US_DV9.ISO'
        }
    }

    'Win2016StdCore' {
        $osData = @{
            os_name = 'win2016stdcore'
            guest_os_type = 'Windows2012_64'
            full_os_name = 'Windows2016StdCore'
            iso_checksum = '3bb1c60417e9aeb3f4ce0eb02189c0c84a1c6691'
            iso_url = 'http://care.dlservice.microsoft.com/dl/download/1/6/F/16FA20E6-4662-482A-920B-1A45CF5AAE3C/14393.0.160715-1616.RS1_RELEASE_SERVER_EVAL_X64FRE_EN-US.ISO'
        }
    }
}

# Base Image
Start-Process -FilePath 'packer.exe' -ArgumentList "build  -var `"os_name=$($osData.os_name)`" -var `"iso_checksum=$($osData.iso_checksum)`" -var `"iso_url=$($osData.iso_url)`" -var `"guest_os_type=$($osData.guest_os_type)`" .\01-windows-base.json" -Wait -NoNewWindow

# Installs Windows Updates and WMF5
Start-Process -FilePath 'packer.exe' -ArgumentList "build  -var `"os_name=$($osData.os_name)`" -var `"source_path=.\output-$($osData.os_name)-base\$($osData.os_name)-base.ovf`" .\02-win_updates-wmf5.json" -Wait -NoNewWindow

# Cleanup
Start-Process -FilePath 'packer.exe' -ArgumentList "build  -var `"os_name=$($osData.os_name)`" -var `"source_path=.\output-$($osData.os_name)-updates_wmf5\$($osData.os_name)-updates_wmf5.ovf`" .\03-cleanup.json" -Wait -NoNewWindow

# Vagrant Image Only
Start-Process -FilePath 'packer.exe' -ArgumentList "build  -var `"os_name=$($osData.os_name)`" -var `"source_path=.\output-$($osData.os_name)-cleanup\$($osData.os_name)-cleanup.ovf`" .\04-local.json" -Wait -NoNewWindow
