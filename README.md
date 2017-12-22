# k8surfer
A resilient Rancher/Kubernetes/CentOS/GlusterFS Cluster built with Terraform/Packer

brew install juju sshuttle charm charm-tools

https://jujucharms.com/docs/devel/help-vmware
juju add-cloud vsphere vsphere.yml
juju clouds

https://jujucharms.com/docs/2.0/credentials
cp credentials.dist.yml credentials.yml
juju add-credential vsphere -f credentials.yml
juju set-default-credential vsphere feffi
juju list-credentials
juju list-credentials --format yaml --show-secrets

juju bootstrap vsphere/esx.power.lab jujucontroller --to zone=esx.power.lab --config primary-network="VM Network" --config external-network="VM Network" --config datastore=ds00

juju bootstrap vsphere jujucontroller --to zone=esx.power.lab --config primary-network="VM Network" --config external-network="VM Network" --config datastore=ds00

juju bootstrap vsphere jujucontroller --config primary-network="VM Network" --config external-network="VM Network" --config datastore=ds00

https://jujucharms.com/juju-gui/142
