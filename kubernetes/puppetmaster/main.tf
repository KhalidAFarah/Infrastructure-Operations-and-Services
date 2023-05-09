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
}
data "openstack_compute_keypair_v2" "laptop" {
  name = "KF-Laptop-key"
}

# resource "openstack_blockstorage_volume_v3" "volume" {
#   name = "${var.name}-volume"
#   size = var.volume_size
#   image_id = data.openstack_images_image_v2.image.id
# }


resource "openstack_compute_instance_v2" "foreman_puppetmaster" {
  provider = openstack
  name        = var.name
  image_name  = var.image_name
  flavor_name = var.flavor_name
  key_pair    = var.key_pair_name
  network {
    name = var.network_name
  }
  security_groups = var.security_groups

  # block_device {
  #   uuid =  openstack_blockstorage_volume_v3.volume.id
  #   source_type = "volume"
  #   destination_type = "volume"
  #   boot_index = 0
  #   delete_on_termination = true
  #   volume_size = var.volume_size
  # }

  connection {
    type        = "ssh"
    user        = var.user
    private_key = var.private_key
    host        = openstack_compute_instance_v2.foreman_puppetmaster.access_ip_v4
  }

  provisioner "file" {
    source      = var.manifest_file
    destination = "./manifest.pp"
  }
  provisioner "file" {
    source      = "./ELK"
    destination = "./ELK"
  }

  provisioner "remote-exec" {
    inline = [
      "sleep 20",
      "echo \"${data.openstack_compute_keypair_v2.laptop.public_key}\" >> .ssh/authorized_keys",
      "echo \"${var.worker_node_public_key}\" >> .ssh/authorized_keys",
      "sudo apt update -y",
      "sudo hostnamectl set-hostname www.${replace(self.name, "_", "")}.openstacklocal",
      "sudo bash -c 'echo \"${openstack_compute_instance_v2.foreman_puppetmaster.access_ip_v4} www.${replace(self.name, "_", "")}.openstacklocal\" >> /etc/hosts'",
      "sudo apt install -y apt-transport-https wget gpg gnupg ca-certificates",
      "curl -LO https://apt.puppet.com/puppet6-release-focal.deb",
      "sudo dpkg -i ./puppet6-release-focal.deb",
      "sudo apt update -y",
      "echo \"deb http://deb.theforeman.org/ focal 3.0\" | sudo tee /etc/apt/sources.list.d/foreman.list",
      "echo \"deb http://deb.theforeman.org/ plugins 3.0\" | sudo tee -a /etc/apt/sources.list.d/foreman.list",
      "wget -q http://deb.theforeman.org/pubkey.gpg -O- | sudo apt-key add -",
      "sudo apt-get update && sudo apt-get -y install foreman-installer",
      "sudo foreman-installer --foreman-initial-admin-username='${var.initial_admin_username}' --foreman-initial-admin-password='${var.initial_admin_password}'"
    ]
  }
  provisioner "remote-exec" {
     inline = var.puppet_modules
    #  when = ((var.puppet_modules != []) ? "create" : "never")
  }
  provisioner "remote-exec" {
    inline = [
      "sed -i 's/puppetmasterip/${openstack_compute_instance_v2.foreman_puppetmaster.access_ip_v4}/g' ~/manifest.pp",
      "sudo mv ~/manifest.pp /etc/puppetlabs/code/environments/production/manifests/manifest.pp",
      "sleep 10",
      "sudo /opt/puppetlabs/puppet/bin/puppet agent -t",# trying -t as first report is a puppet error
      "echo 'done'"
    ]
  }
}