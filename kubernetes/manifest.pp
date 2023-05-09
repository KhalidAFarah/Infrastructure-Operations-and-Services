node 'www.foremanmaster.openstacklocal' {
  include ntp
  include docker
  include kubernetes
  include kubernetes::controller
  include kubernetes::controller::ceph
  include kubernetes::controller::elk
  include kubernetes::controller::prometheus
  include kubernetes::controller::backup

  # exec { "sign_all":
  #   path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
  #   command => "sudo /opt/puppetlabs/bin/puppetserver ca sign --all",
  #   unless => "sudo /opt/puppetlabs/bin/puppetserver ca list | grep -q 'No certificates to list'",
  # }
}

node default {
  include ntp
  include docker
  include kubernetes
  include kubernetes::worker
}

#https://computingforgeeks.com/deploy-kubernetes-cluster-on-ubuntu-with-kubeadm/
#https://computingforgeeks.com/install-mirantis-cri-dockerd-as-docker-engine-shim-for-kubernetes/
class kubernetes { 
  require Class['docker']
  package { ["curl", "apt-transport-https", "wget", "git"]:
    ensure => present,
  }
  exec { "adding_kubernetes_key":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add",
    unless => "sudo apt-key list | grep -q 'Rapture Automatic Signing Key'",
    require => Package['curl', 'apt-transport-https'],
  }
  exec { "adding_to_source_list":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "sudo bash -c \"echo 'deb https://apt.kubernetes.io/ kubernetes-xenial main' >> /etc/apt/sources.list.d/kubernetes.list\"",
    unless => "sudo ls /etc/apt/sources.list.d/kubernetes.list",
    require => Exec['adding_kubernetes_key'],
  }


  exec { "installing_kubelet":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "sudo apt-get -y update && sudo apt-get -y install kubelet && sudo apt-mark hold kubelet",
    unless => "dpkg -l kubelet",
    require => Exec['adding_to_source_list'],
  }
  exec { "installing_kubectl":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "sudo apt-get -y update && sudo apt-get -y install kubectl && sudo apt-mark hold kubectl",
    unless => "dpkg -l kubectl",
    require => Exec['adding_to_source_list', 'installing_kubelet'],
  }
  exec { "installing_kubeadm":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "sudo apt-get -y update && sudo apt-get -y install kubeadm && sudo apt-mark hold kubeadm",
    unless => "dpkg -l kubeadm",
    require => Exec['adding_to_source_list', 'installing_kubectl'],
  }

  exec { "disable_swap":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab && sudo swapoff -a && sudo mount -a",
    onlyif => "grep -q '^/dev' /proc/swaps",
    require => Package['curl', 'apt-transport-https'],
  }

  exec { "network1":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "sudo modprobe overlay && sudo modprobe br_netfilter",
    unless => "lsmod | grep -q '^overlay ' && lsmod | grep -q '^br_netfilter '",
    require => Package['curl', 'apt-transport-https'],
  }
  exec { "network2":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "sudo bash -c \"echo -e 'net.bridge.bridge-nf-call-ip6tables = 1\nnet.bridge.bridge-nf-call-iptables = 1\nnet.ipv4.ip_forward = 1' >> /etc/sysctl.d/kubernetes.conf\" && sudo sysctl --system",
    unless => "sudo ls /etc/sysctl.d/kubernetes.conf && sudo grep 'net.bridge.bridge-nf-call-ip6tables = 1' /etc/sysctl.d/kubernetes.conf && sudo grep 'net.bridge.bridge-nf-call-iptables = 1' /etc/sysctl.d/kubernetes.conf && sudo grep 'net.ipv4.ip_forward = 1' /etc/sysctl.d/kubernetes.conf && sysctl -n net.bridge.bridge-nf-call-ip6tables && sysctl -n net.bridge.bridge-nf-call-iptables && sysctl -n net.ipv4.ip_forward",
    require => Exec['network1'],
  }

  service{ "kubelet":
    enable => true,
    ensure => "running",
    require => Exec['network2'],
  }

  exec { "install_cri":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "sudo wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.1/cri-dockerd-0.3.1.amd64.tgz && sudo tar xvf cri-dockerd-0.3.1.amd64.tgz",
    require => Package['wget', 'git'],
    unless => "sudo ls cri-dockerd",
  }
  exec { "mv_cri":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "sudo mv cri-dockerd/cri-dockerd /usr/local/bin/",
    require => Exec['install_cri'],
    unless => "sudo ls /usr/local/bin/cri-dockerd",
  }

  exec { "install_cri_service":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "sudo wget https://raw.githubusercontent.com/Mirantis/cri-dockerd/master/packaging/systemd/cri-docker.service",
    require => Exec['mv_cri'],
    unless => "sudo ls cri-docker.service",
  }
  exec { "install_cri_socket":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "sudo wget https://raw.githubusercontent.com/Mirantis/cri-dockerd/master/packaging/systemd/cri-docker.socket",
    require => Exec['mv_cri'],
    unless => "sudo ls cri-docker.socket",
  }
  exec { "mv_socket_and_service":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "sudo mv cri-docker.socket cri-docker.service /etc/systemd/system/",
    require => Exec['install_cri_service','install_cri_socket'],
    unless => "sudo ls /etc/systemd/system/cri-docker.socket && sudo ls /etc/systemd/system/cri-docker.service",
  }
  exec { "alter_socket_and_service":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "sudo sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service",
    require => Exec['mv_socket_and_service'],
    unless => "sudo grep '/usr/local/bin/cri-dockerd' /etc/systemd/system/cri-docker.service",
  }
  exec { "reload_daemon":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "sudo systemctl daemon-reload",
    refreshonly => true,
    # require => Exec['alter_socket_and_service'],
    subscribe => [Exec['alter_socket_and_service']]

  }
  service { "cri-docker.service":
    enable => true,
    ensure => 'running',
    require => Exec['alter_socket_and_service','reload_daemon'],
  }
  service { "cri-docker.socket":
    enable => true,
    ensure => 'running',
    # command => "/usr/bin/systemctl start cri-docker.socket --now", #gives error
    require => Exec['alter_socket_and_service','reload_daemon'],
  }
}

#https://computingforgeeks.com/deploy-kubernetes-cluster-on-ubuntu-with-kubeadm/
class kubernetes::controller {
  require Class['kubernetes']

  # service{ "kubelet":
  #   enable => true,
  #   ensure => "running",
  # }

  exec { "kubeadm_start":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --cri-socket=/var/run/cri-dockerd.sock",
    require => Service['kubelet'],
    unless => "sudo ls /etc/kubernetes/admin.conf",
  }

  exec { "setup_kubectl":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "sudo mkdir -p /home/ubuntu/.kube && sudo cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config && sudo chown $(id -u):$(id -g) /home/ubuntu/.kube && sudo chown $(id -u):$(id -g) /home/ubuntu/.kube/config",
    unless => "sudo ls -l /home/ubuntu/.kube/config | grep -q 'ubuntu'",
    require => Exec['kubeadm_start'],
  }

  exec { "install_flannel_network":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "sudo -u ubuntu wget https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml",
    require => Exec['setup_kubectl'],
    unless => "sudo -u ubuntu kubectl get pods -n kube-flannel | grep -q 'kube-flannel'"
  }
  exec { "configure_flannel_network":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "sudo sed -i 's/10.244.0.0/192.168.0.0/g' /home/ubuntu/kube-flannel.yml",
    require => Exec['install_flannel_network'],
    unless => "sudo -u ubuntu kubectl get pods -n kube-flannel | grep -q 'kube-flannel'"
  }
  exec { "run_flannel_network":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "sudo -u ubuntu kubectl create -f /home/ubuntu/kube-flannel.yml",
    require => Exec['configure_flannel_network'],
    unless => "sudo -u ubuntu kubectl get pods -n kube-flannel | grep -q 'kube-flannel'"
  }

  # exec { "setup_calico_network":
  #   path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
  #   user => "ubuntu",
  #   command => "kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.1/manifests/tigera-operator.yaml && kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.1/manifests/custom-resources.yaml",
  #   require => Exec['setup_kubectl'],
  #   unless => "sudo -u ubuntu kubectl get namespaces | grep -q calico-apiserver && sudo -u ubuntu kubectl get namespaces | grep -q calico-system && sudo -u ubuntu kubectl get namespaces | grep -q tigera-operator"
  # }

  # exec { "save_join_token":
  #   path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
  #   command => "sudo kubeadm token create --print-join-command > ",
  #   require => Exec['setup_kubectl'],
  # }
  
  exec { "install_helm":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "sudo snap install helm --classic",
    require => Exec['run_flannel_network'],
    unless => "dpkg -l helm",
  }
}

#https://computingforgeeks.com/deploy-kubernetes-cluster-on-ubuntu-with-kubeadm/
class kubernetes::worker {
  require Class['kubernetes']

  # service{ "kubelet":
  #   enable => true,
  #   ensure => "running",
  # }

  exec { "fetch_join":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "ssh -o StrictHostKeyChecking=no ubuntu@puppetmasterip 'sudo kubeadm token create --print-join-command' | sudo tee /home/ubuntu/token.txt",
    require => Service['kubelet'],
    unless => "sudo ls /etc/kubernetes/kubelet.conf",
  }
  exec { "kubeadm_start":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "sudo $(sudo cat /home/ubuntu/token.txt) --cri-socket=/var/run/cri-dockerd.sock",
    require => Exec['fetch_join'],
    unless => "sudo ls /etc/kubernetes/kubelet.conf",
  }
  exec { "hide_token":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "sudo rm /home/ubuntu/token.txt",
    require => Exec['kubeadm_start'],
    unless => "sudo ls /etc/kubernetes/kubelet.conf",
  }
}


# exec { "kubetool":
  #   path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
  #   command => "docker run --rm -v $(pwd):/mnt -e OS=ubuntu -e VERSION=1.25.3-00 -e CONTAINER_RUNTIME=docker -e CNI_PROVIDER=calico -e CNI_PROVIDER_VERSION=3.25 -e ETCD_INITIAL_CLUSTER=kube-control-plane:172.17.10.101,kube-replica-control-plane-01:172.17.10.210,kube-replica-control-plane-02:172.17.10.220 -e ETCD_IP="%{networking.ip}" -e KUBE_API_ADVERTISE_ADDRESS="%{networking.ip}" -e INSTALL_DASHBOARD=true puppet/kubetool:7.0.0",
  #   unless => "ls /home/ubuntu/Ubuntu.yaml",
  # }
  # exec { "os.yml":
  #   path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
  #   command => "mv /home/ubuntu/Ubuntu.yaml /etc/puppetlabs/code/environments/production/Ubuntu.yaml",
  #   unless => "ls /home/ubuntu/Ubuntu.yaml",
  # }

  # exec { "hiera":
  #   path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
  #   command => "sudo bash -c 'echo \"  - name: \"Family\"\n    path:/home/ubuntu/Ubuntu.yml\n  - name: \"Host\"\n    path: www.foremanmaster.openstacklocal' >> /etc/puppetlabs/code/environments/production/hiera.yaml",
  #   #unless => "",
  # 
  # class {'kubernetes':
  #   docker_apt_location => "https://download.docker.com/linux/ubuntu/",
  #   docker_apt_repos    => "stable",
  #   docker_apt_release  => "focal",
  #   docker_key_source   => "https://download.docker.com/linux/ubuntu/gpg",
  #   docker_package_name => "docker-ce",
  #   controller => true,
  #   kubernetes_apt_location => "https://apt.kubernetes.io/",
  #   kubernetes_apt_release => "kubernetes-xenial",
  #   kubernetes_apt_repos => "main",
  #   kubernetes_key_source => "https://packages.cloud.google.com/apt/doc/apt-key.gpg",
  #   kubernetes_package_version => "1.26.3",
  #   kubernetes_version => "1.26.3",
  #   manage_docker => true,
  #   manage_etcd => true,
  #   etcd_version => "3.5.0", 
  # }

#kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- bash
#https://computingforgeeks.com/how-to-deploy-rook-ceph-storage-on-kubernetes-cluster/
class kubernetes::controller::ceph {
  require Class['kubernetes::controller']

  exec { "install_ceph_git":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "sudo -u ubuntu git clone --single-branch --branch release-1.11 https://github.com/rook/rook.git",
    require => Exec['run_flannel_network'],#Exec['setup_calico_network'],
    unless => "sudo ls /home/ubuntu/rook",
  }

  exec { "create_crds":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "sudo -u ubuntu kubectl create -f /home/ubuntu/rook/deploy/examples/crds.yaml",
    unless => "sudo -u ubuntu kubectl get crds | grep -q 'cephblockpoolradosnamespaces.ceph.rook.io' && \
      sudo -u ubuntu kubectl get crds | grep -q 'cephblockpools.ceph.rook.io' && \
      sudo -u ubuntu kubectl get crds | grep -q 'cephbucketnotifications.ceph.rook.io' && \
      sudo -u ubuntu kubectl get crds | grep -q 'cephbuckettopics.ceph.rook.io' && \
      sudo -u ubuntu kubectl get crds | grep -q 'cephclients.ceph.rook.io' && \
      sudo -u ubuntu kubectl get crds | grep -q 'cephclusters.ceph.rook.io' && \
      sudo -u ubuntu kubectl get crds | grep -q 'cephfilesystemmirrors.ceph.rook.io' && \
      sudo -u ubuntu kubectl get crds | grep -q 'cephfilesystems.ceph.rook.io' && \
      sudo -u ubuntu kubectl get crds | grep -q 'cephfilesystemsubvolumegroups.ceph.rook.io' && \
      sudo -u ubuntu kubectl get crds | grep -q 'cephnfses.ceph.rook.io' && \
      sudo -u ubuntu kubectl get crds | grep -q 'cephobjectrealms.ceph.rook.io' && \
      sudo -u ubuntu kubectl get crds | grep -q 'cephobjectstores.ceph.rook.io' && \
      sudo -u ubuntu kubectl get crds | grep -q 'cephobjectstoreusers.ceph.rook.io' && \
      sudo -u ubuntu kubectl get crds | grep -q 'cephobjectzonegroups.ceph.rook.io' && \
      sudo -u ubuntu kubectl get crds | grep -q 'cephobjectzones.ceph.rook.io' && \
      sudo -u ubuntu kubectl get crds | grep -q 'cephrbdmirrors.ceph.rook.io' && \
      sudo -u ubuntu kubectl get crds | grep -q 'objectbucketclaims.objectbucket.io' && \
      sudo -u ubuntu kubectl get crds | grep -q 'objectbuckets.objectbucket.io'",
    require => Exec['install_ceph_git'],
  }
  exec { "create_common":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "sudo -u ubuntu kubectl create -f /home/ubuntu/rook/deploy/examples/common.yaml",
    unless => "sudo -u ubuntu kubectl get ns rook-ceph",
    require => Exec['create_crds'],
  }
  exec { "create_operator":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "sudo -u ubuntu kubectl create -f /home/ubuntu/rook/deploy/examples/operator.yaml",
    unless => "sudo -u ubuntu kubectl get all -n rook-ceph | grep -q 'pod/rook-ceph-operator' && \
      sudo -u ubuntu kubectl get all -n rook-ceph | grep -q 'deployment.apps/rook-ceph-operator' && \
      sudo -u ubuntu kubectl get all -n rook-ceph | grep -q 'replicaset.apps/rook-ceph-operator'",
    require => Exec['create_common'],
  }
  exec { "create_cluster":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "sudo -u ubuntu kubectl create -n rook-ceph -f /home/ubuntu/rook/deploy/examples/cluster.yaml",
    unless => "sudo -u ubuntu kubectl -n rook-ceph get cephcluster | grep -q rook-ceph",
    require => Exec['create_operator'],
  }

  exec { "create_ceph_toolbox":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "sudo -u ubuntu kubectl create -n rook-ceph -f /home/ubuntu/rook/deploy/examples/toolbox.yaml",
    unless => "sudo -u ubuntu kubectl -n rook-ceph get deployment rook-ceph-tools",
    require => Exec['create_cluster'],
  }
}

#https://computingforgeeks.com/setup-prometheus-and-grafana-on-kubernetes/
class kubernetes::controller::prometheus {
  require Class['kubernetes::controller']

  exec { "install_prometheus_git":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "sudo -u ubuntu git clone https://github.com/prometheus-operator/kube-prometheus.git",
    require => Exec['run_flannel_network'],#Exec['setup_calico_network'],
    unless => "sudo ls /home/ubuntu/kube-prometheus",
  }

  exec { "setup_prometheus_operator":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "sudo -u ubuntu kubectl create -f /home/ubuntu/kube-prometheus/manifests/setup",
    unless => "sudo -u ubuntu kubectl get ns monitoring",
    require => Exec['install_prometheus_git'],
  }
  exec { "run_prometheus_operator":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "sudo -u ubuntu kubectl create -f /home/ubuntu/kube-prometheus/manifests",
    unless => "sudo -u ubuntu kubectl get svc -n monitoring | grep -q 'prometheus-operator' && \
     sudo -u ubuntu kubectl get svc -n monitoring | grep -q 'prometheus-operated' && \
     sudo -u ubuntu kubectl get svc -n monitoring | grep -q 'prometheus-k8s' && \
     sudo -u ubuntu kubectl get svc -n monitoring | grep -q 'prometheus-adapter' && \
     sudo -u ubuntu kubectl get svc -n monitoring | grep -q 'node-exporter' && \
     sudo -u ubuntu kubectl get svc -n monitoring | grep -q 'kube-state-metrics' && \
     sudo -u ubuntu kubectl get svc -n monitoring | grep -q 'grafana' && \
     sudo -u ubuntu kubectl get svc -n monitoring | grep -q 'blackbox-exporter' && \
     sudo -u ubuntu kubectl get svc -n monitoring | grep -q 'alertmanager-operated' && \
     sudo -u ubuntu kubectl get svc -n monitoring | grep -q 'alertmanager-main'",
    require => Exec['setup_prometheus_operator'],
  }

  exec { "show_grafana_dashboard":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "sudo -u ubuntu kubectl expose service grafana --name=grafana-external -n monitoring --type=NodePort --port=3000 --target-port=3000 --external-ip=puppetmasterip",
    require => Exec['run_prometheus_operator'],
    unless => "sudo -u ubuntu kubectl get svc -n monitoring grafana-external",
  }
}


#0.13.9

#https://www.youtube.com/watch?v=vtSUlcN4Kfg
class kubernetes::controller::elk {
  require Class['kubernetes::controller::ceph']

  exec { "install_storage_class":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "sudo -u ubuntu kubectl create -f /home/ubuntu/ELK/storageclass.yaml",
    require => Exec['create_ceph_toolbox'],
    unless => "sudo -u ubuntu kubectl get storageclasses standard",
  }

  exec { "install_filebeat":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "sudo -u ubuntu helm install filebeat /home/ubuntu/ELK/filebeat",
    require => Exec['install_helm'],
    unless => "sudo -u ubuntu kubectl get pods | grep -q 'filebeat'",
  }
  exec { "install_logstash":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "sudo -u ubuntu helm install logstash /home/ubuntu/ELK/logstash",
    require => Exec['install_helm'],
    unless => "sudo -u ubuntu kubectl get svc logstash-logstash",
  }
  exec { "install_elasticsearch":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "sudo -u ubuntu helm install elasticsearch /home/ubuntu/ELK/elasticsearch",
    require => Exec['install_helm'],
    unless => "sudo -u ubuntu kubectl get svc elasticsearch-master",
  }
  exec { "install_kibana":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "kubectl wait --for=condition=Ready --timeout=60m statefulset/elasticsearch-master && sudo -u ubuntu helm install kibana /home/ubuntu/ELK/kibana&",
    require => Exec['install_elasticsearch'],
    unless => "sudo -u ubuntu kubectl get svc kibana-kibana",
    timeout => 900,
  }
  exec { "show_kibana_dashboard":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "kubectl wait --for=condition=Ready --timeout=65m service/kibana-kibana && sudo -u ubuntu kubectl expose service kibana-kibana --name=kibana-external --type=NodePort --port=5601 --target-port=5601 --external-ip=puppetmasterip&",
    require => Exec['install_kibana'],
    unless => "sudo -u ubuntu kubectl get svc kibana-kibana-external",
  }
}


class kubernetes::controller::backup {
  require Class['kubernetes::controller']

  # exec { "add_kasten_repo":
  #   path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
  #   user => "ubuntu",
  #   command => "sudo -u ubuntu helm repo add kasten https://charts.kasten.io/",
  #   require => Exec['install_helm'],
  #   unless => "sudo -u ubuntu helm repo list | grep -q 'kasten'",
  # }
  exec { "install_kasten":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "sudo -u ubuntu helm install my-k10 /home/ubuntu/backup/k10 --namespace=backup --create-namespace",
    require => Exec['install_helm'],
    unless => "sudo -u ubuntu kubectl get deployment my-k10-grafana",
  }

  exec { "show_kasten_dashboard":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "sudo -u ubuntu kubectl expose -n backup service/gateway --port=8000 --target-port=8080 --name=kasten-external --external-ip=puppetmasterip",
    require => Exec['run_prometheus_operator'],
    unless => "sudo -u ubuntu kubectl get svc kasten-external",
  }
}

#0.5.1
#0.20.0
#0.1.0

