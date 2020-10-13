variable "ibmcloud_api_key" {}

variable "region" {
  default = "us-south"
}

variable "ibmcloud_timeout" {
  default = 900
}

variable "basename" {
  default = "openvpn"
}

variable "vpc_ssh_key_name" {
  default = ""
}

variable "tags" {
  default = ["terraform"]
}

variable "vpc_name" {
  description = "Name of an existing VPC where to deploy the bastion"
  default = ""
}

variable server_network {
  default = "10.66.0.0"
}