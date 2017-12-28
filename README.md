# k8surfer
terraform -> ansible -> openshift


ansible: packer(infra, cobbler, etc.)
  -> ansible: upload image (infra)
  -> ansible: provision image


touch openshift.tf


kops create cluster \
--name kube.lab \
--master-count 3 \
--node-count 3 \
--yes \
--encrypt-etcd-storage \
--bastion="true" \
--topology private \
--networking weave \
--network-cidr 10.1.2.0/16 \
--ssh-access 10.1.0.0/16 \
--out=. \
--target=terraform
