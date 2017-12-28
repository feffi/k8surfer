
resource "vsphere_folder" "vsphere_folder" {
  path          = "${var.vsphere_folder}"
  type          = "vm"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

resource "vsphere_virtual_machine" "k8s-master" {
  count = "${var.master_count}"
  datastore_id = "${data.vsphere_datastore.datastore.id}"
  resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
  guest_id = "${data.vsphere_virtual_machine.template.guest_id}" # Pointer to a template to clone into
  scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}" # Pointer to a template to clone into
  folder = "${var.vsphere_folder}"
  name   = "${var.master_name}-0${count.index + 1}"
  num_cpus = 2
  cpu_hot_add_enabled = true
  cpu_hot_remove_enabled = true
  memory = 4096
  memory_hot_add_enabled = true

  disk {
    name             = "${var.master_name}-0${count.index + 1}.vmdk"
    size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.0.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
  }

  disk {
    name             = "${var.master_name}-glusterfs-0${count.index + 1}.vmdk"
    size             = 10
    thin_provisioned = true
    unit_number = 1
  }

  network_interface {
    network_id   = "${data.vsphere_network.network.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"

    customize {
      ipv4_gateway = "${var.network_gateway}"
      dns_suffix_list = ["${var.dns_domain}"]
      dns_server_list = ["${var.dns_server}"]

      linux_options {
        host_name = "${var.master_name}-0${count.index + 1}"
        domain    = "${var.dns_domain}"
      }

      network_interface {
        ipv4_address = "${var.network_master_ip_prefix}${10 + count.index}"
        ipv4_netmask = "${var.network_netmask}"
      }
    }
  }
}

resource "vsphere_virtual_machine" "k8s-worker" {
  count = "${var.worker_count}"
  datastore_id = "${data.vsphere_datastore.datastore.id}"
  resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
  guest_id = "${data.vsphere_virtual_machine.template.guest_id}" # Pointer to a template to clone into
  scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}" # Pointer to a template to clone into
  folder = "${var.vsphere_folder}"
  name   = "${var.worker_name}-0${count.index + 1}"
  num_cpus = 2
  cpu_hot_add_enabled = true
  cpu_hot_remove_enabled = true
  memory = 4096
  memory_hot_add_enabled = true

  disk {
    name             = "${var.worker_name}-0${count.index + 1}.vmdk"
    size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.0.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
  }

  disk {
    name             = "${var.worker_name}-glusterfs-0${count.index + 1}.vmdk"
    size             = 10
    thin_provisioned = true
    unit_number = 1
  }

  network_interface {
    network_id   = "${data.vsphere_network.network.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"

    customize {
      ipv4_gateway = "${var.network_gateway}"
      dns_suffix_list = ["${var.dns_domain}"]
      dns_server_list = ["${var.dns_server}"]

      linux_options {
        host_name = "${var.worker_name}-0${count.index + 1}"
        domain    = "${var.dns_domain}"
      }

      network_interface {
        ipv4_address = "${var.network_worker_ip_prefix}${10 + count.index}"
        ipv4_netmask = "${var.network_netmask}"
      }
    }
  }
}

# Create a DNS A record set
resource "dns_a_record_set" "dns-master" {
  count = "${var.master_count}"
  name  = "${var.master_name}-0${count.index + 1}"
  zone  = "${var.dns_domain}."
  # vsphere_virtual_machine.vms.*.access_ip_v4
  addresses = [
    "${var.network_master_ip_prefix}${10 + count.index}"
  ]
  ttl = "${var.dns_ttl}"
}

# Create a DNS A record set
resource "dns_a_record_set" "dns-worker" {
  count = "${var.worker_count}"
  name  = "${var.worker_name}-0${count.index + 1}"
  zone  = "${var.dns_domain}."
  # vsphere_virtual_machine.vms.*.access_ip_v4
  addresses = [
    "${var.network_worker_ip_prefix}${10 + count.index}"
  ]
  ttl = "${var.dns_ttl}"
}
