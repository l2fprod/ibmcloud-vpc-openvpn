variable bastion_ip {}
variable private_key_pem {}
variable instances {}
variable subnets {}
variable "openvpn_server_network" {
  default = "10.66.0.0"
}