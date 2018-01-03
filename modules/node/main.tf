variable "ssh_public_key" { type = "string", description = "CoreOS authorized key" }
variable "root_ca"        { type = "string", description = "A custom root CA certificate to add" }

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
