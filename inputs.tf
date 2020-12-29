variable "ibmcloud_api_key" {
  description = "IBM Cloud API key to create resources"
}

variable "region" {
  default = "us-south"
  description = "Region where to find and create resources"
}

variable "ibmcloud_timeout" {
  default = 900
}

variable "basename" {
  default = "openvpn"
  description = "Prefix for all resources created by the template"
}

variable "vpc_ssh_key_name" {
  default = ""
  description = "(Optional) Name of an existing VPC SSH key to inject in all created instances"
}

variable "openvpn_server_network" {
  default = "10.66.0.0"
}

variable "tags" {
  default = ["terraform"]
}

variable "existing_resource_group_name" {
  default = ""
  description = "(Optional) Name of an existing resource group where to create resources"
}

variable "existing_vpc_name" {
  default = ""
  description = "(Optional) Name of an existing VPC where to add the bastion"
}

variable "existing_subnet_id" {
  default = ""
  description = "(Optional) ID of an existing subnet where to add the bastion. VPC name must be set too."
}
