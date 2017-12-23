# SET YOUR VCENTER CONNECTION INFORMATION HERE
provider "vsphere" {
  version = "~> 1.1.1"
  user           = "#############################"
  password       = "#############################"
  vsphere_server = "vsphere.local"
  # if you have a self-signed cert
  allow_unverified_ssl = true
}

# Configure the DNS Provider
provider "dns" {
  update {
    server        = "10.1.1.3"
    key_name      = "lab."
    key_algorithm = "hmac-sha512"
    key_secret    = "#############################"
  }
}

data "vsphere_datacenter" "dc" {
  name = "esx.lab"
}

data "vsphere_resource_pool" "pool" {
  name          = "esx.lab/Resources"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_datastore" "datastore" {
  name          = "ds00"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "network" {
  name          = "VM Network"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

variable "vmname_master" {
  default = "openshift-master"
}

variable "vmname_node" {
  default = "openshift-node"
}

variable "master_ip_prefix" {
  default = "10.2.1."
}

variable "node_ip_prefix" {
  default = "10.2.2."
}

variable "vm_gateway" {
  default = "10.1.1.1"
}

variable "vm_netmask" {
  default = 8
}

// default VM domain for guest customization
variable "vmdomain" {
  default = "lab"
}

// map of the VM Network (vmdomain = "vmnetlabel")
variable "vmnetlabel" {
  type = "map"
  default = {
    lab = "VM Network"
  }
}

data "vsphere_virtual_machine" "template" {
  name          = "templates/centos-7-x86_64-minimal-1708"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

variable "vmcount_master" {
  default = "3"
}

variable "vmcount_node" {
  default = "4"
}


variable "openshift_folder" {
  default = "openshift"
}

resource "vsphere_folder" "openshift_folder" {
  path          = "${var.openshift_folder}"
  type          = "vm"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

resource "vsphere_virtual_machine" "vm-master" {
  count = "${var.vmcount_master}"
  datastore_id = "${data.vsphere_datastore.datastore.id}"
  resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
  guest_id = "${data.vsphere_virtual_machine.template.guest_id}" # Pointer to a template to clone into
  scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}" # Pointer to a template to clone into
  folder = "${var.openshift_folder}"

  name   = "${var.vmname_master}-0${count.index + 1}"
  num_cpus = 2
  cpu_hot_add_enabled = true
  cpu_hot_remove_enabled = true
  memory = 4096
  memory_hot_add_enabled = true

  disk {
    name             = "${var.vmname_master}-0${count.index + 1}.vmdk"
    size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.0.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
  }
  network_interface {
    network_id   = "${data.vsphere_network.network.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"

    customize {
      linux_options {
        host_name = "${var.vmname_master}-0${count.index + 1}" # "terraform-test"
        domain    = "${var.vmdomain}" # "test.internal"
      }

      network_interface {
        ipv4_address = "${var.master_ip_prefix}${10 + count.index}" # "10.0.0.10"
        ipv4_netmask = "${var.vm_netmask}"
      }
      ipv4_gateway = "${var.vm_gateway}"
    }
  }
}

resource "vsphere_virtual_machine" "vm-node" {
  count = "${var.vmcount_node}"
  datastore_id = "${data.vsphere_datastore.datastore.id}"
  resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
  guest_id = "${data.vsphere_virtual_machine.template.guest_id}" # Pointer to a template to clone into
  scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}" # Pointer to a template to clone into
  folder = "${var.openshift_folder}"

  name   = "${var.vmname_node}-0${count.index + 1}"
  num_cpus = 2
  cpu_hot_add_enabled = true
  cpu_hot_remove_enabled = true
  memory = 4096
  memory_hot_add_enabled = true

  disk {
    name             = "${var.vmname_node}-0${count.index + 1}.vmdk"
    size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.0.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
  }
  network_interface {
    network_id   = "${data.vsphere_network.network.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"

    customize {
      linux_options {
        host_name = "${var.vmname_node}-0${count.index + 1}" # "terraform-test"
        domain    = "${var.vmdomain}" # "test.internal"
      }

      network_interface {
        ipv4_address = "${var.node_ip_prefix}${10 + count.index}" # "10.0.0.10"
        ipv4_netmask = "${var.vm_netmask}"
      }
      ipv4_gateway = "${var.vm_gateway}"
    }
  }
}

# Create a DNS A record set
resource "dns_a_record_set" "dns-master" {
  count = "${var.vmcount_master}"
  name  = "${var.vmname_master}-0${count.index + 1}"
  zone  = "lab."
  # vsphere_virtual_machine.vms.*.access_ip_v4
  addresses = [
    "${var.master_ip_prefix}${10 + count.index}"
  ]
  ttl = 300
}

# Create a DNS A record set
resource "dns_a_record_set" "dns-node" {
  count = "${var.vmcount_node}"
  name  = "${var.vmname_node}-0${count.index + 1}"
  zone  = "lab."
  # vsphere_virtual_machine.vms.*.access_ip_v4
  addresses = [
    "${var.node_ip_prefix}${10 + count.index}"
  ]
  ttl = 300
}
