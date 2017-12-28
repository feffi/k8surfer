output "bastion_ip" {
    value = "${join("\n", vsphere_virtual_machine.bastion-server.*.public_ip)}"
}

output "masters" {
    value = "${join("\n", vsphere_virtual_machine.k8s-master.*.private_ip)}"
}

output "workers" {
    value = "${join("\n", vsphere_virtual_machine.k8s-worker.*.private_ip)}"
}

output "etcd" {
    value = "${join("\n", vsphere_virtual_machine.k8s-etcd.*.private_ip)}"
}


#output "aws_elb_api_fqdn" {
#    value = "${module.aws-elb.aws_elb_api_fqdn}:${var.aws_elb_api_port}"
#}

output "inventory" {
    value = "${data.template_file.inventory.rendered}"
}

output "default_tags" {
    value = "${default_tags}"
}

/*
* Create Kubespray Inventory File
*
*/
data "template_file" "inventory" {
    template = "${file("${path.module}/templates/inventory.tpl")}"

    vars {
        public_ip_address_bastion = "${join("\n",formatlist("bastion ansible_host=%s" , vsphere_virtual_machine.bastion-server.*.public_ip))}"
        connection_strings_master = "${join("\n",formatlist("%s ansible_host=%s",vsphere_virtual_machine.k8s-master.*.tags.Name, vsphere_virtual_machine.k8s-master.*.private_ip))}"
        connection_strings_node = "${join("\n", formatlist("%s ansible_host=%s", vsphere_virtual_machine.k8s-worker.*.tags.Name, vsphere_virtual_machine.k8s-worker.*.private_ip))}"
        connection_strings_etcd = "${join("\n",formatlist("%s ansible_host=%s", vsphere_virtual_machine.k8s-etcd.*.tags.Name, vsphere_virtual_machine.k8s-etcd.*.private_ip))}"
        list_master = "${join("\n",vsphere_virtual_machine.k8s-master.*.tags.Name)}"
        list_node = "${join("\n",vsphere_virtual_machine.k8s-worker.*.tags.Name)}"
        list_etcd = "${join("\n",vsphere_virtual_machine.k8s-etcd.*.tags.Name)}"
        #elb_api_fqdn = "apiserver_loadbalancer_domain_name=\"${module.aws-elb.aws_elb_api_fqdn}\""
    }

}

resource "null_resource" "inventories" {
  provisioner "local-exec" {
      command = "echo '${data.template_file.inventory.rendered}' > ../../../inventory/hosts"
  }

  triggers {
      template = "${data.template_file.inventory.rendered}"
  }

}
