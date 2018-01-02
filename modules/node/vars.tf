variable "instances"      { type = "string", description = "Number of instances to create" }
variable "folder"         { type = "string", description = "Folder to put the k8s cluster in" }
variable "name"           { type = "string", description = "Name prefix", default = "k8s" }
variable "datastore"      { type = "string", description = "VSphere datastore to use" }
variable "datacenter"     { type = "string", description = "VSphere datacenter to use" }
variable "resource_pool"  { type = "string", description = "VSphere resource pool to use" }
variable "dns_server"     { type = "string", description = "IP of the DNS server" }
variable "ip_prefix"      { type = "string", description = "Master IP prefix" }
variable "ip_gateway"     { type = "string", description = "The default network gateway" }
variable "ip_netmask"     { type = "string", description = "The default CIDR", default = 24 }
variable "ssh_public_key" { type = "string", description = "CoreOS authorized key" }
variable "root_ca"        { type = "string", description = "A custom root CA certificate to add" }
variable "dns_domain"     { type = "string", description = "The default domain" }
variable "dns_ttl"        { type = "string", description = "Default TTL for DNS entries", default = 300 }
