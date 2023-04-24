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

data "openstack_images_image_v2" "name" {
  name = var.image_name
  provider = openstack
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
      "echo 'done'"
    ]
  }
  # provider = var.chosen_provider
  block_device {
        uuid = "${data.openstack_images_image_v2.name.id}"#"f2ef69eb-2856-4319-95f5-902f43fccef8"
        source_type = "image"
        destination_type = "volume"
        volume_size = 10
        boot_index = 0
        delete_on_termination = true
    }
}