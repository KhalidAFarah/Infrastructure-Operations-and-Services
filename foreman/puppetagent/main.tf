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

resource "openstack_compute_instance_v2" "puppetagent" {
  name        = "${var.name}-${count.index}"
  count       = var.number_of_instances
  image_name  = var.image_name
  flavor_name = var.flavor_name
  key_pair    = var.key_pair_name
  network {
    name = var.network_name
  }
  connection {
    type        = "ssh"
    user        = var.user
    private_key = var.private_key
    host        = self.access_ip_v4
  }

  provisioner "remote-exec" {
    inline = [
      "sleep 20",
      "sudo apt update -y",
      "curl -LO https://apt.puppet.com/puppet7-release-focal.deb",
      "sudo dpkg -i ./puppet7-release-focal.deb",
      "sudo apt update",
      "sudo apt-get install puppet-agent -y",
      "sudo bash -c 'echo -e \"[main]\ncertname=www.${replace(self.name, "_", "")}.openstacklocal\nserver=www.${replace(var.puppetmaster_name, "_", "")}.openstacklocal\nruninterval=${var.runinterval}\" >> /etc/puppetlabs/puppet/puppet.conf'",
      "sudo bash -c 'echo -e \"${var.puppetmaster_ip} www.${replace(var.puppetmaster_name, "_", "")}.openstacklocal ${replace(var.puppetmaster_name, "_", "")}\" >> /etc/hosts'",
      "sudo bash -c 'echo -e \"${self.access_ip_v4} www.${self.name}.openstacklocal ${self.name}\" >> /etc/hosts'",
      "sudo systemctl start puppet",
      "sudo /opt/puppetlabs/puppet/bin/puppet agent",
    ]
  }
  # provider = var.chosen_provider
}