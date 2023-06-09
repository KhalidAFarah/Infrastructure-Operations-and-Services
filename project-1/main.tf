terraform {
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
    }
  }
}
# provider "openstack" {
#   cloud = "alto"
#   alias = "al"
# }
provider "openstack" {
  cloud = "safespring"
  alias = "safe"
}
#mysql uses port 3306, loadbalance and webservers probably should use port 80, 443 and 8140 
module "puppetmaster_securitygroup" {
  source = "./securitygroup"
  chosen_provider = "safespring"
  name = "Puppetmaster securitygroup"
  description = "The security group for the puppetmaster"
  rules = {
    "ssh" = {
      "ip_protocol" = "tcp"
      "to_port" = "22"
      "from_port" = "22"
      "ethertype" = "IPv4"
      "cidr" = "0.0.0.0/0"
    }
    "http" = {
      "ip_protocol" = "tcp"
      "to_port" = "80"
      "from_port" = "80"
      "ethertype" = "IPv4"
      "cidr" = "0.0.0.0/0"
    }
    "https" = {
      "ip_protocol" = "tcp"
      "to_port" = "443"
      "from_port" = "443"
      "ethertype" = "IPv4"
      "cidr" = "0.0.0.0/0"
    }
    "httpstwo" = {
      "ip_protocol" = "tcp"
      "to_port" = "8140"
      "from_port" = "8140"
      "ethertype" = "IPv4"
      "cidr" = "0.0.0.0/0"
    }
    "puppetserver" = {
      "ip_protocol" = "tcp"
      "to_port" = "8443"
      "from_port" = "8443"
      "ethertype" = "IPv4"
      "cidr" = "0.0.0.0/0"
    }
  } 
}

module "web_securitygroup" {
  source = "./securitygroup"
  chosen_provider = "safespring"
  name = "webservers and loadbalancer securitygroup"
  description = "The security group for the webservers and the loadbalancers"
  rules = {
    "ssh" = {
      "ip_protocol" = "tcp"
      "to_port" = "22"
      "from_port" = "22"
      "ethertype" = "IPv4"
      "cidr" = "0.0.0.0/0"
    }
    "http" = {
      "ip_protocol" = "tcp"
      "to_port" = "80"
      "from_port" = "80"
      "ethertype" = "IPv4"
      "cidr" = "0.0.0.0/0"
    }
    "https" = {
      "ip_protocol" = "tcp"
      "to_port" = "443"
      "from_port" = "443"
      "ethertype" = "IPv4"
      "cidr" = "0.0.0.0/0"
    }
    "httpstwo" = {
      "ip_protocol" = "tcp"
      "to_port" = "8140"
      "from_port" = "8140"
      "ethertype" = "IPv4"
      "cidr" = "0.0.0.0/0"
    }
  }
}

module "database_securitygroup" {
  source = "./securitygroup"
  chosen_provider = "safespring"
  name = "databaseserver securitygroup"
  description = "The security group for the database servers"
  rules = {
    "ssh" = {
      "ip_protocol" = "tcp"
      "to_port" = "22"
      "from_port" = "22"
      "ethertype" = "IPv4"
      "cidr" = "0.0.0.0/0"
    }
    "mysql" = {
      "ip_protocol" = "tcp"
      "to_port" = "3306"
      "from_port" = "3306"
      "ethertype" = "IPv4"
      "cidr" = "0.0.0.0/0"
    }
  } 
}

resource "openstack_compute_keypair_v2" "safe_controller_key" {
  name = "devkey"
  provider = openstack.safe
  public_key = file("~/.ssh/id_rsa.pub")
}


module "puppetmaster" {
  source          = "./puppetmaster"
  chosen_provider = "safespring"

  name          = "puppetmaster"
  image_name    = "ubuntu-20.04"
  flavor_name   = "l2.c2r4.100"
  key_pair_name = "devkey"
  network_name  = "public"
  security_groups = [ module.puppetmaster_securitygroup.name ]
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

module "puppetagent_loadbalancer" {
  source          = "./puppetagent"
  chosen_provider = "safespring"

  name                = "loadbalancer"
  number_of_instances = 1
  image_name          = "ubuntu-20.04"
  flavor_name         = "b2.c1r2"
  key_pair_name       = "devkey"
  network_name        = "public"
  security_groups = [ module.web_securitygroup.name ]

  user              = "ubuntu"
  private_key       = file("~/.ssh/id_rsa")#openstack_compute_keypair_v2.safe_controller_key.private_key
  puppetmaster_ip   = module.puppetmaster.puppetmaster_ip
  puppetmaster_name = module.puppetmaster.puppetmaster_name
  runinterval       = "1m"

  delete_volume_on_termination = true
  volume_size = 10
}

module "puppetagent_databaseservers" {
  source          = "./puppetagent"
  chosen_provider = "safespring"

  name                = "databaseserver"
  number_of_instances = 2
  image_name          = "ubuntu-20.04"
  flavor_name         = "b2.c1r2"
  key_pair_name       = "devkey"
  network_name        = "default"
  security_groups = [ module.database_securitygroup.name ]

  user              = "ubuntu"
  private_key       = file("~/.ssh/id_rsa")#openstack_compute_keypair_v2.safe_controller_key.private_key
  puppetmaster_ip   = module.puppetmaster.puppetmaster_ip
  puppetmaster_name = module.puppetmaster.puppetmaster_name
  runinterval       = "1m"

  delete_volume_on_termination = true
  volume_size = 10
}

module "puppetagent_webservers" {
  source          = "./puppetagent"
  chosen_provider = "safespring"

  name                = "webserver"
  number_of_instances = 2
  image_name          = "ubuntu-20.04"
  flavor_name         = "b2.c1r2"
  key_pair_name       = "devkey"
  network_name        = "default"
  security_groups = [ module.web_securitygroup.name ]

  user              = "ubuntu"
  private_key       = file("~/.ssh/id_rsa")#openstack_compute_keypair_v2.safe_controller_key.private_key
  puppetmaster_ip   = module.puppetmaster.puppetmaster_ip
  puppetmaster_name = module.puppetmaster.puppetmaster_name
  runinterval       = "1m"

  delete_volume_on_termination = true
  volume_size = 10
}

# module "puppetagent_backup" {
#   source          = "./puppetagent"
#   chosen_provider = "alto"

#   name                = "backup"
#   number_of_instances = 1
#   image_name          = "Ubuntu-20.04-LTS"
#   flavor_name         = "m1.small"
#   key_pair_name       = "controller"
#   network_name        = "netsys_net"
#   security_groups = [ "default" ]

#   user              = "ubuntu"
#   private_key       = file("~/.ssh/id_rsa")
#   puppetmaster_ip   = module.puppetmaster.puppetmaster_ip
#   puppetmaster_name = module.puppetmaster.puppetmaster_name
#   runinterval       = "1m"

#   delete_volume_on_termination = true
#   volume_size = 10
# }




output "puppetmaster_ip" {
  value = module.puppetmaster.puppetmaster_ip
}
output "puppetagent_loadbalancer_ip" {
  value = module.puppetagent_loadbalancer.puppetagents_ip
}
output "puppetagent_databaseservers_ip" {
  value = module.puppetagent_databaseservers.puppetagents_ip
}
output "puppetagent_webservers_ip" {
  value = module.puppetagent_webservers.puppetagents_ip
}
# output "puppetagent_backupservers_ip" {
#   value = module.puppetagent_backup.puppetagents_ip
# }

#-------------------------- script on backup -------------------------- 
# terraform {
#   required_providers {
#     openstack = {
#       source = "terraform-provider-openstack/openstack"
#     }
#   }
# }
# provider "openstack" {
#   cloud = "alto"
#   alias = "al"
# }
# provider "openstack" {
#   cloud = "safespring"
#   alias = "safe"
# }

# variable "puppetmaster_ip" {
#   type = string
# }

# module "backup_securitygroup" {
#   source = "./securitygroup"
#   chosen_provider = "alto"
#   name = "backup server securitygroup"
#   description = "The security group for the backup servers"
#   rules = {
#     "ssh" = {
#       "ip_protocol" = "tcp"
#       "to_port" = "22"
#       "from_port" = "22"
#       "ethertype" = "IPv4"
#       "cidr" = "0.0.0.0/0"
#     }
#   }
# }
# module "puppetagent_backup" {
#   source          = "./puppetagent"
#   chosen_provider = "alto"

#   name                = "backup"
#   number_of_instances = 1
#   image_name          = "Ubuntu-20.04-LTS"
#   flavor_name         = "m1.small"
#   key_pair_name       = "controller"
#   network_name        = "netsys_net"
#   security_groups = [ "backup server securitygroup" ]

#   user              = "ubuntu"
#   private_key       = file("~/.ssh/id_rsa")
#   puppetmaster_ip   = var.puppetmaster_ip#data.openstack_compute_instance_v2.name.access_ip_v4 #module.puppetmaster.puppetmaster_ip
#   puppetmaster_name = "puppetmaster"#data.openstack_compute_instance_v2.name.name #module.puppetmaster.puppetmaster_name
#   runinterval       = "1m"

#   delete_volume_on_termination = true
#   volume_size = 10
# }

# output "puppetagent_backupservers_ip" {
#   value = module.puppetagent_backup.puppetagents_ip
# }
# output "puppetagent_test" {
#   value = var.puppetmaster_ip
# }