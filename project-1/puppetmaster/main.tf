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

  provisioner "remote-exec" {
    inline = [
      "sleep 20",
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
      "sudo foreman-installer --foreman-initial-admin-password='${var.initial_admin_username}' --foreman-initial-admin-password='${var.initial_admin_password}'"
    ]
  }
  provisioner "remote-exec" {
     inline = var.puppet_modules
     #when = var.puppet_modules != []
  }
  provisioner "remote-exec" {
    inline = [
      "sudo mv ~/manifest.pp /etc/puppetlabs/code/environments/production/manifests/manifest.pp",
      "sudo /opt/puppetlabs/puppet/bin/puppet agent"
      ]
  }
  # provider    = var.chosen_provider
}