# terraform {
#   required_providers {
#     openstack = {
#       source = "terraform-provider-openstack/openstack"
#     }
#   }
# }

# provider "openstack" {
#   cloud = "openstack"
#   alias = "os"
# }

module "puppetmaster" {
  source          = "./puppetmaster"
  # chosen_provider = openstack.os

  name          = "foreman_master"
  image_name    = "ubuntu-20.04"
  flavor_name   = "l2.c2r4.100"
  key_pair_name = "Controller key"
  network_name  = "public"

  user          = "ubuntu"
  private_key   = file("~/.ssh/id_rsa")
  manifest_file = "./manifest.pp"
  puppet_modules = [
    "sudo /opt/puppetlabs/bin/puppet module install -i /etc/puppetlabs/code/environments/production/modules puppetlabs-ntp --version 9.2.1",
    "sudo /opt/puppetlabs/bin/puppet module install -i /etc/puppetlabs/code/environments/production/modules puppetlabs-docker --version 6.0.2"
  ]
  initial_admin_username = "admin"
  initial_admin_password = "temp_pass"

}

module "puppetagent" {
  source          = "./puppetagent"
  # chosen_provider = openstack.os

  name                = "foreman_agent"
  number_of_instances = 2
  image_name          = "ubuntu-20.04"
  flavor_name         = "l2.c2r4.100"
  key_pair_name       = "Controller key"
  network_name        = "default"

  user              = "ubuntu"
  private_key       = file("~/.ssh/id_rsa")
  puppetmaster_ip   = module.puppetmaster.puppetmaster_ip
  puppetmaster_name = module.puppetmaster.puppetmaster_name
  runinterval       = "1m"
}

output "puppetmaster_ip" {
  value = module.puppetmaster.puppetmaster_ip
}
output "puppetagents_ip" {
  value = module.puppetagent.puppetagents_ip
}