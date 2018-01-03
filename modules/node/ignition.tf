variable "ip_prefix" { type = "string" }
variable "ip" {
  type        = "map"
  description = "Network settings to maintain."

  default = {
    gateway       = ""
    netmask       = 24
    prefix_master = ""
    prefix_worker = ""
    prefix_etcd   = ""
  }
}

data "ignition_networkd_unit" "node" {
  count = "${var.instances}"
  name  = "00-ens192.network"
  content = <<EOF
    [Match]
    Name=ens192
    [Network]
    DNS=${var.dns["server"]}
    Address=${var.ip_prefix}${10 + count.index}/${var.ip["netmask"]}
    Gateway=${var.ip["gateway"]}
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
