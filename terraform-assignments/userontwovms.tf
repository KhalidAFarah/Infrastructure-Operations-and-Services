terraform {
  required_providers {
    openstack = {
        source = "terraform-provider-openstack/openstack"
    }
  }
}

provider "openstack" {
    cloud = "openstack"
}

data "openstack_images_image_v2" "ubuntu" {
  name = "ubuntu-22.04"
}

resource "openstack_compute_instance_v2" "ubuntu_puppet_agent" {
  name = "ubuntu-with-user-kate"
  image_id = "${data.openstack_images_image_v2.ubuntu.id}"
  flavor_name = "l2.c2r4.100"
  key_pair = "Controller key"

  network {
    name = "default"
  }

  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = "${file("~/.ssh/id_rsa")}"
    host = openstack_compute_instance_v2.ubuntu_puppet_agent.access_ip_v4
  }

  provisioner "file" {
    source = "../puppet/assignments.pp"
    destination = "/home/ubuntu/assignments.pp"
  }

  provisioner "remote-exec" {
    inline = [
      "sleep 20",
      "sudo apt update",
      "sudo apt -y install puppet",
      "sudo puppet apply ./assignments.pp"
    ]  
  }
}

resource "openstack_compute_instance_v2" "debian_puppet_agent" {
  name = "debian-with-user-kate"
  image_name = "debian-11"
  flavor_name = "l2.c2r4.100"
  key_pair = "Controller key"

  network {
    name = "default"
  }

  connection {
    type = "ssh"
    user = "debian"
    private_key = "${file("~/.ssh/id_rsa")}"
    host = openstack_compute_instance_v2.debian_puppet_agent.access_ip_v4
  }

  provisioner "file" {
    source = "../puppet/assignments.pp"
    destination = "/home/debian/assignments.pp"
  }

  provisioner "remote-exec" {
    inline = [
      "sleep 20",
      "sudo apt update",
      "sudo apt -y install puppet",
      "sudo puppet apply ./assignments.pp"
    ]  
  }
}
