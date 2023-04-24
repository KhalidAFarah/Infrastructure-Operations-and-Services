output "puppetmaster_id" {
  value = openstack_compute_instance_v2.foreman_puppetmaster.id
}
output "puppetmaster_name" {
  value = openstack_compute_instance_v2.foreman_puppetmaster.name
}
output "puppetmaster_ip" {
  value = openstack_compute_instance_v2.foreman_puppetmaster.access_ip_v4
}