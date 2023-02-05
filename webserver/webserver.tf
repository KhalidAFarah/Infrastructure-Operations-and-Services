terraform {
  required_providers{
    openstack = {
        source = "terraform-provider-openstack/openstack"
    }
  }
}

provider "openstack" {
  cloud = "openstack"
}

#Install puppet agent
resource "openstack_compute_instance_v2" "webserver" {
  name          = "Webserver"
  image_name    = "ubuntu-22.04"
  flavor_name   = "l2.c2r4.100"
  key_pair      = "Controller key"
  network {
    name = "public"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = "${file("~/.ssh/id_rsa")}"
    host        = openstack_compute_instance_v2.webserver.access_ip_v4
  }

  provisioner "file" {
    source = "./index.html"
    destination = "/home/ubuntu/index.html"
    
  }
  
  provisioner "file" {
    source = "./webserver_cron.pp"
    destination = "/home/ubuntu/webserver_cron.pp"
    
  }
  provisioner "file" {
    source = "./webserver_manifest.pp"
    destination = "/home/ubuntu/webserver_manifest.pp"
    
  }

  provisioner "remote-exec" {
    inline = [
        "sleep 20",
        "sudo apt update",
        "sudo apt -y install puppet",
        "sudo puppet apply /home/ubuntu/webserver_cron.pp",
        "sudo puppet apply /home/ubuntu/webserver_manifest.pp",
    ]
  }
}

output "Server_IP" {
  value = openstack_compute_instance_v2.webserver.access_ip_v4
}