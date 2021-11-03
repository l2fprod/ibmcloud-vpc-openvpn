variable "ibmcloud_api_key" {
  description = "IBM Cloud API key to create resources"
}

variable "region" {
  default     = "us-south"
  description = "Region where to find and create resources"
}

variable "ibmcloud_timeout" {
  default = 900
}

variable "basename" {
  default     = "openvpn"
  description = "Prefix for all resources created by the template"
}

variable "vpc_ssh_key_name" {
  default     = ""
  description = "(Optional) Name of an existing VPC SSH key to inject in all created instances"
}

variable "openvpn_server_network" {
  default = "10.66.0.0"
}

variable "tags" {
  default = ["terraform"]
}

variable "existing_resource_group_name" {
  default     = ""
  description = "(Optional) Name of an existing resource group where to create resources"
}

variable "existing_vpc_name" {
  default     = ""
  description = "(Optional) Name of an existing VPC where to add the bastion"
}

variable "existing_subnet_id" {
  default     = ""
  description = "(Optional) ID of an existing subnet where to add the bastion. VPC name must be set too."
}

variable "additional_vpc_ids_to_route_to" {
  default     = []
  type        = list(string)
  description = "(Optional) IDs of additional VPCs to include in the OpenVPN routing configuration. This will retrieve all subnet CIDRs of these VPCs."
}

variable "additional_routes" {
  default     = []
  type        = list(string)
  description = "(Optional) Additional arbitrary routes to add to the OpenVPN routing configuration. Array of host/mask such as 10.0.0.1 255.255.255.0."
}

variable "create_one_instance" {
  default     = true
  description = "Whether to create a VSI instance in the created VPC"
}

variable "create_vpe_for_ibmcloud_api" {
  default     = false
  description = "Whether to create VPEs for IBM Cloud APIs inside the bastion subnet"
}
