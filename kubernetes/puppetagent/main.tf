terraform {
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
    }
  }
}
provider "openstack" {
  cloud = var.chosen_provider
}

data "openstack_images_image_v2" "image" {
  name = var.image_name
  provider = openstack
}

# data "openstack_compute_keypair_v2" "laptop" {
#   name = "KF-Laptop-key"
# }

# resource "openstack_blockstorage_volume_v3" "volume" {
#   name = "${var.name}-volume-${count.index}"
#   size = var.volume_size
#   count = var.number_of_instances
#   image_id = data.openstack_images_image_v2.image.id
# }

resource "openstack_blockstorage_volume_v3" "ceph_volume" {
  name = "ceph-volume-${count.index}"
  size = 40
  count       = var.number_of_instances
  # image_id = data.openstack_images_image_v2.image.id
}


resource "openstack_compute_instance_v2" "puppetagent" {
  provider = openstack
  name        = "${var.name}-${count.index}"
  count       = var.number_of_instances
  image_name  = var.image_name
  flavor_name = var.flavor_name
  key_pair    = var.key_pair_name
  network {
    name = var.network_name
  }
  security_groups = var.security_groups
  
  connection {
    type        = "ssh"
    user        = var.user
    private_key = var.private_key
    host        = self.access_ip_v4
  }

  provisioner "remote-exec" {
    inline = [
      "sleep 20",
      # "echo \"${data.openstack_compute_keypair_v2.laptop.public_key}\" >> ~/.ssh/authorized_keys",
      "echo \"${var.worker_node_private_key}\" >> .ssh/id_rsa",
      "chmod 700 .ssh/id_rsa",
      "echo \"${var.worker_node_public_key}\" >> .ssh/id_rsa.pub",
      "sudo apt update -y",
      "curl -LO https://apt.puppet.com/puppet7-release-focal.deb",
      "sudo dpkg -i ./puppet7-release-focal.deb",
      "sudo apt update -y",
      "sudo apt-get install puppet-agent -y",
      "sudo bash -c 'echo -e \"[main]\ncertname=www.${replace(self.name, "_", "")}.openstacklocal\nserver=www.${replace(var.puppetmaster_name, "_", "")}.openstacklocal\nruninterval=${var.runinterval}\" >> /etc/puppetlabs/puppet/puppet.conf'",
      "sudo bash -c 'echo -e \"${var.puppetmaster_ip} www.${replace(var.puppetmaster_name, "_", "")}.openstacklocal ${replace(var.puppetmaster_name, "_", "")}\" >> /etc/hosts'",
      "sudo bash -c 'echo -e \"${self.access_ip_v4} www.${self.name}.openstacklocal ${self.name}\" >> /etc/hosts'",
      "sudo systemctl start puppet",
      "sudo /opt/puppetlabs/puppet/bin/puppet agent",
    ]
  }
  
  # block_device {
  #   uuid =  openstack_blockstorage_volume_v3.volume[count.index].id
  #   source_type = "volume"
  #   destination_type = "volume"
  #   boot_index = 0
  #   delete_on_termination = true
  #   volume_size = var.volume_size
  # }
  # block_device {
  #   uuid =  openstack_blockstorage_volume_v3.ceph_volume[count.index].id
  #   source_type = "volume"
  #   destination_type = "volume"
  #   # boot_index = 1
  #   delete_on_termination = true
  #   volume_size = 40
  # }
}

resource "openstack_compute_volume_attach_v2" "name" {
  instance_id = openstack_compute_instance_v2.puppetagent[count.index].id
  volume_id = openstack_blockstorage_volume_v3.ceph_volume[count.index].id
  # delete_on_termination = true
  count = var.number_of_instances
  
}