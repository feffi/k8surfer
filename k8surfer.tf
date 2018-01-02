variable "ssh_public_key" { type = "string", description = "CoreOS authorized key" }
variable "root_ca"        { type = "string", description = "A custom root CA certificate to add" }

variable "names" {
  type = "map"
  description = "Instance name prefixes."
  default = {
    master = "master"
    worker = "worker"
    etcd   = "etcd"
  }
}

variable "vsphere" {
  type = "map"
  description = "VSphere instance to maintain."
  default = {
    user          = "administrato@vsphere.local"
    pass          = ""
    server        = ""
    datacenter    = ""
    datastore     = ""
    resource_pool = ""
  }
}

variable "instances" {
  type = "map"
  description = "Number of instances of each type to maintain."
  default = {
    master = 3
    worker = 4
    etcd   = 3
  }
}

variable "dns" {
  type = "map"
  description = "The DNS server to maintain."
  default = {
    server    = ""
    domain    = ""
    ttl       = ""
    algorithm = ""
    secret    = ""
  }
}

variable "ip" {
  type = "map"
  description = "Network settings to maintain."
  default = {
    gateway       = ""
    netmask       = 24
    prefix_master = ""
    prefix_worker = ""
    prefix_etcd   = ""
  }
}

provider "vsphere" {
  version = ">= 1.1.1"
  user           = "${var.vsphere["user"]}"
  password       = "${var.vsphere["pass"]}"
  vsphere_server = "${var.vsphere["server"]}"

  # if you have a self-signed cert
  allow_unverified_ssl = true
}

# Configure the DNS Provider
provider "dns" {
  version = ">= 1.0.0"
  update {
    server        = "${var.dns["server"]}"
    key_name      = "${var.dns["domain"]}."
    key_algorithm = "${var.dns["algorithm"]}"
    key_secret    = "${var.dns["secret"]}"
  }
}

terraform {
  required_version = ">= 0.11.1"
}

provider "null" {
  version = ">= 1.0"
}

provider "template" {
  version = ">= 1.0"
}

provider "ignition" {
  version = ">= 1.0.0"
}

data "vsphere_datacenter" "dc" {
  name = "${var.vsphere["datacenter"]}"
}

resource "vsphere_folder" "folder" {
  path          = "${var.folder}"
  type          = "vm"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

module "master" {
  source         = "./modules/node"
  name           = "${var.names["master"]}"
  instances      = "${var.instances["master"]}"
  datacenter     = "${var.vsphere["datacenter"]}"
  datastore      = "${var.vsphere["datastore"]}"
  resource_pool  = "${var.vsphere["resource_pool"]}"
  folder         = "${var.vsphere["folder"]}"
  dns_server     = "${var.dns["server"]}"
  dns_domain     = "${var.dns["domain"]}"
  dns_ttl        = "${var.dns["ttl"]}"
  ip_prefix      = "${var.ip["prefix_master"]}"
  ip_netmask     = "${var.ip["netmask"]}"
  ip_gateway     = "${var.ip["gateway"]}"
  ssh_public_key = "${var.ssh_public_key}"
  root_ca        = "${var.root_ca}"
}

module "worker" {
  source         = "./modules/node"
  name           = "${var.names["worker"]}"
  instances      = "${var.instances["worker"]}"
  datacenter     = "${var.vsphere["datacenter"]}"
  datastore      = "${var.vsphere["datastore"]}"
  resource_pool  = "${var.vsphere["resource_pool"]}"
  folder         = "${var.vsphere["folder"]}"
  dns_server     = "${var.dns["server"]}"
  dns_domain     = "${var.dns["domain"]}"
  dns_ttl        = "${var.dns["ttl"]}"
  ip_prefix      = "${var.ip["prefix_worker"]}"
  ip_netmask     = "${var.ip["netmask"]}"
  ip_gateway     = "${var.ip["gateway"]}"
  ssh_public_key = "${var.ssh_public_key}"
  root_ca        = "${var.root_ca}"
}

/*
* Create Kubespray Inventory File
*
*/
data "template_file" "inventory" {
  template = "${file("${path.module}/inventory.tpl")}"
  vars {
    connection_strings_master = "${join("\n",formatlist("%s ansible_host=%s", module.master.names, module.master.ips))}"
    connection_strings_worker = "${join("\n",formatlist("%s ansible_host=%s", module.worker.names, module.worker.ips))}"
    list_master = "${join("\n",module.master.names)}"
    list_worker = "${join("\n",module.worker.names)}"
  }
}

output "inventory" {
  value = "${data.template_file.inventory.rendered}"
}

resource "null_resource" "inventories" {
  provisioner "local-exec" {
    command = "echo '${data.template_file.inventory.rendered}' > hosts"
  }
  triggers {
    template = "${data.template_file.inventory.rendered}"
  }
}
