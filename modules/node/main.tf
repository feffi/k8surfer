data "ignition_networkd_unit" "node" {
  count = "${var.instances}"
  name  = "00-ens192.network"
  content = <<EOF
    [Match]
    Name=ens192
    [Network]
    DNS=${var.dns_server}
    Address=${var.ip_prefix}${10 + count.index}/${var.ip_netmask}
    Gateway=${var.ip_gateway}
EOF
}

# Set the hostname
data "ignition_file" "hostname" {
  count      = "${var.instances}"
  filesystem = "root"
  path       = "/etc/hostname"
  mode       = 420
  content {
    content = "${var.name}-0${count.index}"
  }
}

data "ignition_disk" "root" {
  device = "/dev/sda"
  partition {
    label = "ROOT"
  }
}

data "ignition_disk" "glusterfs" {
  device = "/dev/sdb"
  partition {
    label = "glusterfs"
  }
}

data "ignition_filesystem" "root" {
  name = "root"
  mount {
    device          = "/dev/disk/by-label/ROOT"
    format          = "btrfs"
    wipe_filesystem = true
    options         = ["-L", "ROOT"]
  }
}

# Define the core users authorized key
data "ignition_user" "core" {
  name = "core"
  ssh_authorized_keys = [ "${var.ssh_public_key}" ]
  groups = [ "sudo" ]
}

# Add custom root ca certificate
data "ignition_file" "root_ca" {
    filesystem = "root"
    path = "/etc/ssl/certs/lab.pem"
    mode = 420
    content {
      content = "${var.root_ca}"
    }
}

# Ingnition config include the previous defined systemd unit data resource
data "ignition_config" "node" {
  count = "${var.instances}"
  networkd = [
    "${data.ignition_networkd_unit.node.*.id[count.index]}"
  ]

  disks = [
    "${data.ignition_disk.root.id}",
    "${data.ignition_disk.glusterfs.id}"
  ]

  filesystems = [
    "${data.ignition_filesystem.root.id}"
  ]

  files = [
    "${data.ignition_file.hostname.*.id[count.index]}",
    "${data.ignition_file.root_ca.id}"
  ]

  users = [
    "${data.ignition_user.core.id}"
  ]
}

resource "vsphere_virtual_machine" "node" {
  count                  = "${var.instances}"
  datastore_id           = "${data.vsphere_datastore.datastore.id}"
  resource_pool_id       = "${data.vsphere_resource_pool.pool.id}"
  guest_id               = "${data.vsphere_virtual_machine.template.guest_id}"
  scsi_type              = "${data.vsphere_virtual_machine.template.scsi_type}"
  folder                 = "${var.folder}"
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

# Create a DNS A record set
resource "dns_a_record_set" "dns" {
  count     = "${var.instances}"
  name      = "${var.name}-0${count.index}"
  zone      = "${var.dns_domain}."
  ttl       = "${var.dns_ttl}"
  addresses = [
    "${var.ip_prefix}${10 + count.index}"
  ]
}

output "names" {
  value = "${vsphere_virtual_machine.node.*.name}"
}

output "ips" {
  value = "${vsphere_virtual_machine.node.*.default_ip_address}"
}

output "nodes" {
  value = [
    "${zipmap(vsphere_virtual_machine.node.*.name, vsphere_virtual_machine.node.*.default_ip_address)}"
  ]
}

output "dns" {
  value = [
    "${zipmap(vsphere_virtual_machine.node.*.name, dns_a_record_set.dns.*.id)}"
  ]
}
