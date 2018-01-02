[all]
${connection_strings_master}
${connection_strings_worker}

[k8s-master]
${list_master}

[k8s-worker]
${list_worker}

[etcd]
${list_master}

[k8s-cluster:children]
k8s-master
k8s-worker

[k8s-cluster:vars]
