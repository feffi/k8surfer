# Vagrant box configuration details image of the os to use
$os = "centos/7"

# IP prefix to use when assigning box ip addresses
$ip_prefix = '10.0.0'

# Enable syncing of the current directory to the /vagrant path on the guest
$disable_folder_sync = false

$provisioning = {
  "playbook-master"   => "main-master.yml",
  "playbook-worker"   => "main-worker.yml",
  "playbook-balancer" => "main-balancer.yml",
  "remote_user"       => "vagrant",
  "become"            => true,
  "become_user"       => "root",
  "extra_vars"        => nil
}

# Proxy configure on boxes, defaults to none if not defined
#$proxies = {
#  "http" => "http://<ip or url>:<port>/",
#  "https" => "https://<ip or url>:<port>/",
#  "no_proxy" => "localhost,127.0.0.1,<ip or url>"
#}

# Boxes to create in the vagrant environment
$boxes = [
    {
      "name"   => "k8s-master",
      "role"   => "master",
      "count"  => 2,
      "memory" => "1024"
    },
    {
      "name"   => "k8s-worker",
      "role"   => "worker",
      "count"  => 2,
      "memory" => "1024"
    },
#    {
#      "name"   => "k8s-balancer",
#      "role"   => "balancer",
#      "count"  => 0,
#      "memory" => "1024"
#    }
]
