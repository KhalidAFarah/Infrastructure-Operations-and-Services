variable "chosen_provider" {
  type        = string
  description = "The provider to use."
}

variable "rules" {
  type = map(map(string))
  description = "Security group rules which is a map that contains a map of string values."
}
variable "name" {
  type = string
  description = "Security group name."
}
variable "description" {
  type = string
  description = "Security group description."
}
variable "delete_default_rules" {
  type = bool
  description = "Delete the default rules set by provider."
  default = false
}