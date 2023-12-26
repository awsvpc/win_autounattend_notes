variable "base_image_ocid" {
  default = env("BASE_IMAGE_OCID")
}

variable "compartment_ocid" {
  default = env("COMPARTMENT_OCID")
}

variable "subnet_ocid" {
  default = env("SUBNET_OCID")
}

variable "admin_username" {
  default = env("ADMIN_USERNAME")
}

variable "admin_password" {
  default = env("ADMIN_PASSWORD")
}

variable "key_file" {
  default = env("KEY_FILE")
}

variable "region" {
  default = env("PACKER_BUILD_REGION")
}

variable "tenancy_ocid" {
  default = env("OCI_CLI_TENANCY")
}

variable "user_ocid" {
  default = env("OCI_CLI_USER")
}

variable "fingerprint" {
  default = env("OCI_CLI_FINGERPRINT")
}

variable "thetoken" {
  default = env("TOKEN")
}

variable "thevaultpass" {
  default = env("VAULT_PASS")
}

