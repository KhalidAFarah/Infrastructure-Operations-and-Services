# variable "chosen_provider" {
#   type        = string
#   description = "The provider to use"
# }
variable "name" {
  type        = string
  description = "Name as the instance name"
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

variable "user" {
  type        = string
  description = "The user used for remote-exec"
}
variable "private_key" {
  type        = string
  description = "The private key used for remote-exec"
}
variable "manifest_file" {
  type        = string
  description = "The puppet manifest file path for the puppetserver"
}
variable "puppet_modules" {
  type        = list(string)
  description = "The default hostgroup file path for foreman"
}

variable "initial_admin_username" {
  type = string
  description = "The initial admin username for foreman"
}
variable "initial_admin_password" {
  type = string
  description = "The initial admin password for foreman"
}