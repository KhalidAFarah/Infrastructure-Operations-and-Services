node 'www.foremanmaster.openstacklocal' {
  include ntp
  include docker
  include kubernetes
  include kubernetes::controller

  exec { "sign_all":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    command => "sudo /opt/puppetlabs/bin/puppetserver ca sign --all",
    unless => "sudo /opt/puppetlabs/bin/puppetserver ca list | grep -q 'No certificates to list'",
  }
}

node default {
  include ntp
  include docker
  include kubernetes
  include kubernetes::worker
}


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
  exec { "installing_kubeadm":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "sudo apt-get -y update && sudo apt-get -y install kubeadm && sudo apt-mark hold kubeadm",
    unless => "dpkg -l kubeadm",
    require => Exec['adding_to_source_list'],
  }
  exec { "installing_kubectl":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "sudo apt-get -y update && sudo apt-get -y install kubectl && sudo apt-mark hold kubectl",
    unless => "dpkg -l kubectl",
    require => Exec['adding_to_source_list'],
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

  exec { "setup_calico_network":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    user => "ubuntu",
    command => "kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.1/manifests/tigera-operator.yaml && kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.1/manifests/custom-resources.yaml",
    require => Exec['setup_kubectl'],
    unless => "sudo -u ubuntu kubectl get namespaces | grep -q calico-apiserver && sudo -u ubuntu kubectl get namespaces | grep -q calico-system && sudo -u ubuntu kubectl get namespaces | grep -q tigera-operator"
  }

  # exec { "save_join_token":
  #   path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
  #   command => "sudo kubeadm token create --print-join-command > ",
  #   require => Exec['setup_kubectl'],
  # }
}

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
