variable bastion_ip {}
variable private_key_pem {}
variable instances {}
variable subnets {}
variable additional_routes {
  default = []
}
variable "openvpn_server_network" {
  default = "10.66.0.0"
}
variable "client_name" {}
