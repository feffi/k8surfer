variable "instances" { type = "string", description = "Number of instances to create" }
variable "name"      { type = "string", description = "Name prefix", default = "k8s" }
variable "vsphere" {
  type        = "map"
  description = "VSphere instance to maintain."
  default = {
    user          = "administrator@vsphere.local"
    pass          = ""
    server        = ""
    datacenter    = ""
    datastore     = ""
    resource_pool = ""
    folder        = "k8s"
    template      = ""
  }
}

provider "vsphere" {
  version        = ">= 1.1.1"
  user           = "${var.vsphere["user"]}"
  password       = "${var.vsphere["pass"]}"
  vsphere_server = "${var.vsphere["server"]}"

  # if you have a self-signed cert
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = "${var.vsphere["datacenter"]}"
}

data "vsphere_resource_pool" "pool" {
  name          = "${var.vsphere["resource_pool"]}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_datastore" "datastore" {
  name          = "${var.vsphere["datastore"]}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "network" {
  name          = "VM Network"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_virtual_machine" "template" {
  name          = "${var.vsphere["template"]}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

resource "vsphere_folder" "folder" {
  path          = "${var.vsphere["folder"]}"
  type          = "vm"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

resource "vsphere_virtual_machine" "node" {
  count                  = "${var.instances}"
  datastore_id           = "${data.vsphere_datastore.datastore.id}"
  resource_pool_id       = "${data.vsphere_resource_pool.pool.id}"
  guest_id               = "${data.vsphere_virtual_machine.template.guest_id}"
  scsi_type              = "${data.vsphere_virtual_machine.template.scsi_type}"
  folder                 = "${var.vsphere["folder"]}"
  name                   = "${var.name}-0${count.index}"
  num_cpus               = 2
  cpu_hot_add_enabled    = true
  cpu_hot_remove_enabled = true
  memory                 = 4096
  memory_hot_add_enabled = true

  disk {
    name             = "${var.name}-0${count.index}.vmdk"
    size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.0.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
  }

  disk {
    name             = "${var.name}-glusterfs-0${count.index}.vmdk"
    size             = 10
    thin_provisioned = true
    unit_number      = 1
  }

  network_interface {
    network_id   = "${data.vsphere_network.network.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  extra_config {
    guestinfo.coreos.config.data.encoding = "base64"
    guestinfo.coreos.config.data          = "${base64encode(data.ignition_config.node.*.rendered[count.index])}"
    #guestinfo.coreos.config.data         = "${data.ignition_config.node.*.rendered[count.index]}"
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"
  }
}
