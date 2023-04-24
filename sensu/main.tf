terraform {
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
    }
  }
}
provider "openstack" {
  cloud = "safespring"
}


data "openstack_images_image_v2" "image" {
  name = "ubuntu-20.04"
  
}

data "openstack_compute_keypair_v2" "laptop" {
  name = "KF-Laptop-key"
}

resource "openstack_blockstorage_volume_v3" "volume" {
  name = "sensu_volume"
  size = 10
  image_id = data.openstack_images_image_v2.image.id
}


resource "openstack_compute_instance_v2" "sensu_master" {
  #provider = openstack
  name        = "sensu"
  image_name  = "ubuntu-20.04"
  flavor_name = "l2.c2r4.100"
  key_pair    = "Controller key"
  network {
    name = "public"
  }
  security_groups = ["default"]

  block_device {
    uuid =  openstack_blockstorage_volume_v3.volume.id#data.openstack_images_image_v2.image.id#openstack_blockstorage_volume_v3.volume.id
    source_type = "volume"
    destination_type = "volume"
    boot_index = 0
    delete_on_termination = true
    volume_size = 10
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = openstack_compute_instance_v2.sensu_master.access_ip_v4
  }

  provisioner "file" {
    source = "./cpu-metrics.yml"
    destination = "./cpu-metrics.yml"
  }
  provisioner "file" {
    source = "./memory-metrics.yml"
    destination = "./memory-metrics.yml"
  }
  provisioner "file" {
    source = "./influxdb-datasource.yml"
    destination = "./influxdb-datasource.yml"
  }

  provisioner "remote-exec" {
    inline = [
        "sleep 20",
        "curl -s https://packagecloud.io/install/repositories/sensu/stable/script.deb.sh | sudo bash",
        "sudo apt-get -y update && sudo apt-get -y install sensu-go-backend",
        "sudo curl -L https://docs.sensu.io/sensu-go/latest/files/backend.yml -o /etc/sensu/backend.yml",
        "sudo service sensu-backend start",
        "export SENSU_BACKEND_CLUSTER_ADMIN_USERNAME=adminuser",
        "export SENSU_BACKEND_CLUSTER_ADMIN_PASSWORD=adminpass",
        "sensu-backend init",

        "sudo apt-get -y update && sudo apt-get -y install sensu-go-cli",
        "sensuctl configure -n --username 'adminuser' --password 'adminpass' --namespace 'default' --url 'http://127.0.0.1:8080'",

        "sudo apt-get -y update && sudo apt-get -y install sensu-go-agent",
        "sudo curl -L https://docs.sensu.io/sensu-go/latest/files/agent.yml -o /etc/sensu/agent.yml",
        "sudo service sensu-agent start",



        "sensuctl asset add sensu-plugins/sensu-plugins-cpu-checks:4.1.0 -r memory-checks-plugins",
        "sensuctl asset add sensu/sensu-ruby-runtime:0.0.10 -r sensu-ruby-runtime",
        "sensuctl check create check-memory —command ‘check-memory.rb -w 75 -c 90’ —interval 60 —subscriptions system —runtime-assets cpu-checks-plugins,sensu-ruby-runtime",

        "sudo mkdir /etc/sensu/checks",
        "sudo mv ./memory-metrics.yml /etc/sensu/checks/memory-metrics.yml",
        "sensuctl create -f /etc/sensu/checks/memory-metrics.yml",
        
        "sudo mv ./cpu-metrics.yml /etc/sensu/checks/cpu-metrics.yml",
        "sudo service sensu-agent restart",

        # "wget https://dl.influxdata.com/influxdb/releases/influxdb2-2.6.1-amd64.deb",
        # "sudo dpkg -i influxdb2-2.6.1-amd64.deb",
        # "sudo systemctl start influxdb",
        # "sudo apt install influxdb-client",

        "sudo apt install -y apt-transport-https",
        "sudo add-apt-repository \"deb https://packages.grafana.com/oss/deb stable main\"",
        "wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -",
        "sudo apt -y update && sudo apt -y install grafana",
        "sudo sed -i 's/^;http_port = 3000/http_port = 4000/' /etc/grafana/grafana.ini",
        "sudo mv ./influxdb-datasource.yml /etc/grafana/provisioning/datasources/influxdb-datasource.yml",
        "sudo systemctl start grafana-server",
        "sudo systemctl enable grafana-server",

    ]
  }
}

output "instance" {
  value = openstack_compute_instance_v2.sensu_master.access_ip_v4
  sensitive = false
}