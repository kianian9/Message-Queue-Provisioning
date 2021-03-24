variable "zone" {
  description = "zone"
}

variable "region" {
  description = "region"
}

variable "ssh_username" {
  description = "SSH user name to connect to your instance."
}

variable "ssh_pub_key_path" {
  description = "Path to the public SSH key, used to access the instance."
}
variable "ssh_prv_key_path" {
  description = "Path to the private SSH key, used to access the instance."
}
