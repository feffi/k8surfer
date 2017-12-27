variable "vsphere_user"             { type = "string" }
variable "vsphere_pass"             { type = "string" }
variable "vsphere_server"           { type = "string" }
variable "vsphere_datacenter"       { type = "string" }
variable "vsphere_resource_pool"    { type = "string" }
variable "vsphere_datastore"        { type = "string" }
variable "vsphere_folder"           { type = "string" }
variable "network_master_ip_prefix" { type = "string" }
variable "network_node_ip_prefix"   { type = "string" }
variable "network_gateway"          { type = "string" }
variable "network_netmask"          { type = "string", default = 24 }
variable "dns_server"               { type = "string" }
variable "dns_domain"               { type = "string" }
variable "dns_key_name"             { type = "string" }
variable "dns_key_algorithm"        { type = "string" }
variable "dns_key_secret"           { type = "string" }
variable "dns_ttl"                  { type = "string", default = 300 }
variable "master_count"             { type = "string", default = 1 }
variable "master_name"              { type = "string", default = "openshift-master"}
variable "node_count"               { type = "string", default = 1 }
variable "node_name"                { type = "string", default = "openshift-node" }
