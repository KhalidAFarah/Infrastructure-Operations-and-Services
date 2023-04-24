output "puppetagents_id" {
  value = openstack_compute_instance_v2.puppetagent.*.id
}
output "puppetagents_name" {
  value = openstack_compute_instance_v2.puppetagent.*.name
}
output "puppetagents_ip" {
  value = openstack_compute_instance_v2.puppetagent.*.access_ip_v4
}