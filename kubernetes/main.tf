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

resource "openstack_compute_keypair_v2" "worker_nodes_ssh_key_pair" {
  name = "worker_nodes_ssh_key_pair"
}

module "puppetmaster" {
  source          = "./puppetmaster"
  chosen_provider = "safespring"

  name          = "foreman_master"
  image_name    = "ubuntu-20.04"
  flavor_name   = "b2.c4r8"
  key_pair_name = "Controller key"
  network_name  = "public"
  security_groups = [ "default" ]
  volume_size = 100
  user          = "ubuntu"
  private_key   = file("~/.ssh/id_rsa")#.safe_controller_key.private_key
  manifest_file = "./manifest.pp"
  puppet_modules = [
    # "sudo /opt/puppetlabs/bin/puppet module install -i /etc/puppetlabs/code/environments/production/modules puppet-augeasproviders_core --version 3.2.0",
    # "sudo /opt/puppetlabs/bin/puppet module install -i /etc/puppetlabs/code/environments/production/modules herculesteam-augeasproviders_sysctl --version 2.6.2 --ignore-dependencies",
    # "sudo /opt/puppetlabs/bin/puppet module install -i /etc/puppetlabs/code/environments/production/modules puppetlabs-kubernetes --version 7.1.0",
    "sudo /opt/puppetlabs/bin/puppet module install -i /etc/puppetlabs/code/environments/production/modules puppetlabs-ntp --version 9.2.1",
    "sudo /opt/puppetlabs/bin/puppet module install -i /etc/puppetlabs/code/environments/production/modules puppetlabs-docker --version 5.1.0",
  ]
  initial_admin_username = "temp_admin"
  initial_admin_password = "temp_pass"

  worker_node_public_key = openstack_compute_keypair_v2.worker_nodes_ssh_key_pair.public_key

}

module "puppetagent" {
  source          = "./puppetagent"
  chosen_provider = "safespring"

  name                = "foreman_agent"
  number_of_instances = 3
  image_name          = "ubuntu-20.04"
  flavor_name         = "b2.c2r4"
  key_pair_name       = "Controller key"
  network_name        = "default"
  volume_size = 10
  security_groups = [ "default" ]

  user              = "ubuntu"
  private_key       = file("~/.ssh/id_rsa")
  puppetmaster_ip   = module.puppetmaster.puppetmaster_ip
  puppetmaster_name = module.puppetmaster.puppetmaster_name
  runinterval       = "15m"

  worker_node_private_key = openstack_compute_keypair_v2.worker_nodes_ssh_key_pair.private_key
  worker_node_public_key = openstack_compute_keypair_v2.worker_nodes_ssh_key_pair.public_key
}

output "puppetmaster_ip" {
  value = module.puppetmaster.puppetmaster_ip
}
output "puppetagents_ip" {
  value = module.puppetagent.puppetagents_ip
}