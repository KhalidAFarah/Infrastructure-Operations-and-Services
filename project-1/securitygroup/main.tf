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

resource "openstack_networking_secgroup_v2" "security_group" {
    name = var.name
    description = var.description
    delete_default_rules = var.delete_default_rules
}

resource "openstack_networking_secgroup_rule_v2" "security_group_rules" {
    for_each           = var.rules
    direction          = try(each.value.direction, "ingress")
    ethertype          = try(each.value.ethertype , "IPv4")
    protocol           = try(each.value.ip_protocol, null)
    remote_group_id    = try(each.value.remote_group_id, null) == "self" ? openstack_networking_secgroup_v2.security_group.id : try(each.value.remote_group_id, null)
    port_range_min     = try(each.value.from_port, null)
    port_range_max     = try(each.value.to_port, null)
    remote_ip_prefix   = try(each.value.cidr, null)
    security_group_id  = openstack_networking_secgroup_v2.security_group.id
  
}