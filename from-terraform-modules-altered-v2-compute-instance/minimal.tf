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

# resource "openstack_compute_instance_v2" "mini_ubuntu" {
#     name        = "miniubuntu"
#     image_name  = "ubuntu-20.04"
#     flavor_name = "l2.c2r4.100"
#     key_pair = "Controller key"

#     network {
#       name = "default"
#     }
# }

# resource "openstack_compute_instance_v2" "mini_debian" {
#     name        = "minidebian"
#     image_name  = "debian-11"
#     flavor_name = "l2.c2r4.100"
#     key_pair    = "Controller key"
#     network {
#       name = "default"
#     }
# }

# resource "openstack_compute_instance_v2" "count_instance" {
#     count       = 2
#     name        = "mini-${count.index}"
#     image_name  = "ubuntu-20.04"
#     flavor_name = "l2.c2r4.100"
#     key_pair    = "Controller key"
  
#     network {
#       name = "default"
#     }
# }

# output "IPv4" {
#   value = openstack_compute_instance_v2.count_instance.*.access_ip_v4
# }