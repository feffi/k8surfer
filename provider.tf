provider "vsphere" {
  version        = "~> 1.1.1"
  user           = "${var.vsphere_user}"
  password       = "${var.vsphere_pass}"
  vsphere_server = "${var.vsphere_server}"

  # if you have a self-signed cert
  allow_unverified_ssl = true
}

# Configure the DNS Provider
provider "dns" {
  version         = ">= 1.0.0"
  update {
    server        = "${var.dns_server}"
    key_name      = "${var.dns_key_name}"
    key_algorithm = "${var.dns_key_algorithm}"
    key_secret    = "${var.dns_key_secret}"
  }
}

terraform {
  required_version = ">= 0.11.1"
}
