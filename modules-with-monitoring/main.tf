module "puppetmaster" {
  source          = "./puppetmaster"
  chosen_provider = "safespring"

  name          = "puppetmaster"
  image_name    = "ubuntu-20.04"
  flavor_name   = "l2.c2r4.100"
  key_pair_name = "Controller key"
  network_name  = "public"
  security_groups = [ "default" ]
  user          = "ubuntu"
  private_key   = file("~/.ssh/id_rsa")#.safe_controller_key.private_key
  manifest_file = "./manifest.pp"
  puppet_modules = [
    "sudo /opt/puppetlabs/bin/puppet module install -i /etc/puppetlabs/code/environments/production/modules puppetlabs-ntp --version 9.2.1",
    "sudo /opt/puppetlabs/bin/puppet module install -i /etc/puppetlabs/code/environments/production/modules puppet-php --version 8.2.0",
    #"sudo /opt/puppetlabs/bin/puppet module install -i /etc/puppetlabs/code/environments/production/modules saz-sudo --version 7.0.2",
  ]
  initial_admin_username = "admin"
  initial_admin_password = "temp_pass"

}

module "puppetagent" {
  source          = "./puppetagent"
  chosen_provider = "safespring"

  name                = "puppetagent"
  number_of_instances = 1
  image_name          = "ubuntu-20.04"
  flavor_name         = "b2.c1r2"
  key_pair_name       = "Controller key"
  network_name        = "public"
  security_groups = [ "default" ]

  user              = "ubuntu"
  private_key       = file("~/.ssh/id_rsa")#openstack_compute_keypair_v2.safe_controller_key.private_key
  puppetmaster_ip   = module.puppetmaster.puppetmaster_ip
  puppetmaster_name = module.puppetmaster.puppetmaster_name
  runinterval       = "1m"

  delete_volume_on_termination = true
  volume_size = 10
}


output "ip_puppetmaster" {
  value = module.puppetmaster.puppetmaster_ip
}