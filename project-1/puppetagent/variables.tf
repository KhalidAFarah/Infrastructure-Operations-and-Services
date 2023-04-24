variable "chosen_provider" {
  type        = string
  description = "The provider to use"
}
variable "name" {
  type        = string
  description = "Name as the instance name"
}
variable "number_of_instances" {
  type        = number
  description = "number of instances"
  default     = 1
}
variable "image_name" {
  type        = string
  description = "Image name of the OS"
}
variable "flavor_name" {
  type        = string
  description = "Flavor name for the resource allocated to the instance"
}
variable "key_pair_name" {
  type        = string
  description = "The key pair for logging into the server with ssh"
}
variable "network_name" {
  type        = string
  description = "The name of the used for the instance"
}
variable "security_groups" {
  type        = list(string)
  description = "List of security groups"
}

variable "user" {
  type        = string
  description = "The user used for remote-exec"
}
variable "private_key" {
  type        = string
  description = "The private key used for remote-exec"
}
variable "puppetmaster_ip" {
  type        = string
  description = "Puppet master ip address"
}
variable "puppetmaster_name" {
  type        = string
  description = "Puppet master name"
}
variable "runinterval" {
  type        = string
  description = "runinterval before agent checks and reruns puppet policy."
  default     = "10m"
}

variable "delete_volume_on_termination" {
  type        = bool
  description = "delete the volume attached on termination of instance."
  default     = false
}
variable "volume_size" {
  type        = number
  description = "How many gigabytes should be given to the volume attached to the instance."
}
