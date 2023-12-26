packer {
    required_plugins {
    oracle = {
        version = ">= 1.0.4"
        source = "github.com/hashicorp/oracle"
        }
    }
}

source "oracle-oci" "server2019" {
  communicator        = "winrm"
  availability_domain = "Qvhu:US-ASHBURN-AD-1"
  base_image_ocid     = var.base_image_ocid
  compartment_ocid    = var.compartment_ocid
  image_name          = "vod_oseries9_windows_server_2019_{{ isotime }}"
  shape               = "VM.Optimized3.Flex"
  shape_config {
    ocpus         = 2
    memory_in_gbs = 16
  }
  subnet_ocid    = var.subnet_ocid
  winrm_username = var.admin_username
  winrm_password = var.admin_password
  winrm_insecure = true
  winrm_use_ssl  = true
  use_private_ip = true
  user_data_file = "./user_data.ps1"
  

  # authentication default overrides
  region       = var.region
  tenancy_ocid = var.tenancy_ocid
  user_ocid    = var.user_ocid
  key_file     = var.key_file
  fingerprint  = var.fingerprint
}

build {
  sources = ["source.oracle-oci.server2019"]
  provisioner "powershell" {
    elevated_user = var.admin_username
    elevated_password = var.admin_password
    scripts = [
      "./powershell/Disable-IEEnhancedSecurity.ps1",
      "./powershell/Disable-WindowsFirewall.ps1",
      "./powershell/Remove-WindowsDefender.ps1",
      "./powershell/Install-WindowsFeatures.ps1",
      "./powershell/Install-PowershellCore.ps1",
      "./powershell/Install-PackageProviders.ps1",
      "./powershell/Install-PowershellModules.ps1",
      "./powershell/Install-psresourceget.ps1"
      #"./powershell/Invoke-WindowsUpdate.ps1"
      #"./powershell/Install-Git.ps1",
    ]
  }

  provisioner "windows-restart" {}

  provisioner "powershell" {
    environment_vars = [
      "THETOKEN=${var.thetoken}",
      "THEVAULTPASS=${var.thevaultpass}",
			"THECOMPARTMENT_OCID=${var.compartment_ocid}",
			"THESUBNET_OCID=${var.subnet_ocid}",
			"THEBASE_IMAGE_OCID=${var.base_image_ocid}",
			"THEOCI_USER=${var.user_ocid}",
			"THE_FINGERPRINT=${var.fingerprint}",
			"THEADMIN_USERNAME=${var.admin_username}",
			"THEADMIN_PASSWORD=${var.admin_password}",
			"THETENANCY_OCID=${var.tenancy_ocid}",
      "THEREGION=${var.region}"
    ]
    elevated_user = var.admin_username
    elevated_password = var.admin_password
    script = "./powershell/get-env.ps1"
  }
  
}