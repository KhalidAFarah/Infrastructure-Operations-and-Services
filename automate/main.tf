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

data "openstack_images_image_v2" "ubuntu_22" {
  name = "ubuntu-22.04"
}

resource "openstack_compute_instance_v2" "puppet_master" {
    name = "puppet_master"
    image_id = "${data.openstack_images_image_v2.ubuntu_22.id}"
    flavor_name = "l2.c2r4.100"
    key_pair = "Controller key"
    network {
      name = "public"
    }

    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = "${file("~/.ssh/id_rsa")}"
      host = openstack_compute_instance_v2.puppet_master.access_ip_v4
    }

    provisioner "file" {
      source = "./manifest.pp"
      destination = "/home/ubuntu/manifest.pp"
    }

    provisioner "remote-exec" {
        inline = [
          "sleep 20",
          "sudo apt update -y",
          "sudo bash -c 'echo \"${openstack_compute_instance_v2.puppet_master.access_ip_v4} puppetmaster.openstacklocal puppetmaster\" >> /etc/hosts'",
          "curl -LO https://apt.puppet.com/puppet7-release-focal.deb",
          "sudo dpkg -i ./puppet7-release-focal.deb",
          "sudo apt update",
          "sudo apt -y install puppetserver",
          "sudo bash -c 'echo -e \"dns_alt_names=puppetmaster.openstacklocal,puppetmaster\n\n[main]\ncertname=puppetmaster.openstacklocal\nserver=puppetmaster.openstacklocal\nenvironment=production\nruninterval=10m\" >> /etc/puppetlabs/puppet/puppet.conf'",
          "sudo /opt/puppetlabs/bin/puppetserver ca setup",
          "sudo mv /home/ubuntu/manifest.pp /etc/puppetlabs/code/environments/production/manifests/manifest.pp",
          "sudo systemctl start puppetserver",
          "sudo apt-get install puppet-agent -y",
          "sudo /opt/puppetlabs/bin/puppet config set server puppetmaster",
          "sudo /opt/puppetlabs/puppet/bin/puppet agent",
        ]
    }
}

resource "openstack_compute_instance_v2" "puppet_agent" {
    name = "puppet-agent"
    image_id = "${data.openstack_images_image_v2.ubuntu_22.id}"
    flavor_name = "l2.c2r4.100"
    key_pair = "Controller key"
    network {
      name = "default"
    }

    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = "${file("~/.ssh/id_rsa")}"
      host = openstack_compute_instance_v2.puppet_agent.access_ip_v4
    }

    provisioner "remote-exec" {
        inline = [
          "sleep 20",
          "sudo apt update -y",
          "curl -LO https://apt.puppet.com/puppet7-release-focal.deb",
          "sudo dpkg -i ./puppet7-release-focal.deb",
          "sudo apt update",
          "sudo apt-get install puppet-agent -y",
          "sudo bash -c 'echo -e \"[main]\ncertname=${openstack_compute_instance_v2.puppet_agent.name}.openstacklocal\nserver=puppetmaster.openstacklocal\" >> /etc/puppetlabs/puppet/puppet.conf'",
          "sudo bash -c 'echo -e \"${openstack_compute_instance_v2.puppet_master.access_ip_v4} puppetmaster.openstacklocal puppetmaster\" >> /etc/hosts'",
          "sudo bash -c 'echo -e \"${openstack_compute_instance_v2.puppet_agent.access_ip_v4} ${openstack_compute_instance_v2.puppet_agent.name}.openstacklocal ${openstack_compute_instance_v2.puppet_agent.name}\" >> /etc/hosts'",
          "sudo systemctl start puppet",
          "sudo /opt/puppetlabs/puppet/bin/puppet agent",
        ]
    } 
}

output "puppet_master_ip" {
  value = openstack_compute_instance_v2.puppet_master.access_ip_v4
}

output "puppet_agent_ip" {
  value = openstack_compute_instance_v2.puppet_agent.access_ip_v4
}