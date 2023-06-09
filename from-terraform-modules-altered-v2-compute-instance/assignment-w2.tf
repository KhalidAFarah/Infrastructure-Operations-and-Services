# terraform {
#   required_providers{
#     openstack = {
#         source = "terraform-provider-openstack/openstack"
#     }
#   }
# }

# provider "openstack" {
#   cloud = "openstack"
# }

# #Install puppet agent
# resource "openstack_compute_instance_v2" "puppet_agent" {
#   name          = "Puppet agent"
#   image_name    = "ubuntu-22.04"
#   flavor_name   = "l2.c2r4.100"
#   key_pair      = "Controller key"
#   network {
#     name = "default"
#   }

#   connection {
#     type        = "ssh"
#     user        = "ubuntu"
#     private_key = "${file("~/.ssh/id_rsa")}"
#     host        = openstack_compute_instance_v2.puppet_agent.access_ip_v4
#   }

#   provisioner "remote-exec" {
#     inline = [
#         "sleep 20",
#         "sudo apt update",
#         "sudo apt -y install puppet"
#     ]
#   }
# }

