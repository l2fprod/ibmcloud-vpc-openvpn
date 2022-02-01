#
# Create a resource group or reuse an existing one
#
resource "ibm_resource_group" "group" {
  count = var.existing_resource_group_name != "" ? 0 : 1
  name  = "${var.basename}-group"
  tags  = var.tags
}

data "ibm_resource_group" "group" {
  count = var.existing_resource_group_name != "" ? 1 : 0
  name  = var.existing_resource_group_name
}

locals {
  resource_group_id = var.existing_resource_group_name != "" ? data.ibm_resource_group.group.0.id : ibm_resource_group.group.0.id
}

#
# Use a new SSH key to run ansible and optionally inject an existing SSH key
#
data "ibm_is_ssh_key" "sshkey" {
  count = var.vpc_ssh_key_name != "" ? 1 : 0
  name  = var.vpc_ssh_key_name
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "ibm_is_ssh_key" "generated_key" {
  name           = "${var.basename}-${var.region}-key"
  public_key     = tls_private_key.ssh.public_key_openssh
  resource_group = local.resource_group_id
  tags           = concat(var.tags, ["vpc"])
}

locals {
  ssh_key_ids = var.vpc_ssh_key_name != "" ? [data.ibm_is_ssh_key.sshkey[0].id, ibm_is_ssh_key.generated_key.id] : [ibm_is_ssh_key.generated_key.id]
}

#
# Optionally create a VPC or load an existing one
#
module "vpc" {
  count = var.existing_vpc_name != "" ? 0 : 1

  source            = "./vpc"
  name              = "${var.basename}-vpc"
  region            = var.region
  cidr_blocks       = ["10.10.10.0/24"]
  resource_group_id = local.resource_group_id
  tags              = var.tags
}

data "ibm_is_vpc" "vpc" {
  count = var.existing_vpc_name != "" ? 1 : 0
  name  = var.existing_vpc_name
}

locals {
  vpc = var.existing_vpc_name != "" ? data.ibm_is_vpc.vpc.0 : module.vpc.0.vpc
}

#
# Retrieve the VPC subnets (so it populates all fields like ipv4_cidr_block)
#
data "ibm_is_subnet" "subnet" {
  count      = var.existing_vpc_name != "" ? length(local.vpc.subnets) : 0
  identifier = local.vpc.subnets[count.index].id
}

data "ibm_is_subnets" "existing_subnets" {
  count      = 1
  depends_on = [module.bastion]
}

data "ibm_is_subnet" "existing_subnet" {
  count      = var.existing_subnet_id != "" ? 1 : 0
  identifier = var.existing_subnet_id
}

locals {
  subnets = var.existing_vpc_name != "" ? [
    for subnet in data.ibm_is_subnets.existing_subnets.0.subnets :
    subnet if subnet.vpc == data.ibm_is_vpc.vpc.0.id
  ] : module.vpc.0.subnets

  # the bastion subnet id is:
  # - the one specified explicitely in the config
  # - or the first of the VPC specified explicitely
  # - of the first of the VPC created by the template
  bastion_subnet_id = var.existing_subnet_id != "" ? data.ibm_is_subnet.existing_subnet.0.id : (
    var.existing_vpc_name != "" ? data.ibm_is_vpc.vpc.0.subnets.0.id : module.vpc.0.subnets.0.id
  )
  create_one_instance = var.existing_vpc_name == "" && tobool(var.create_one_instance)
}

#
# Optionally create instances
#
module "instance" {
  count = local.create_one_instance ? 1 : 0

  source            = "./instance"
  name              = "${var.basename}-instance"
  resource_group_id = local.resource_group_id
  vpc_id            = local.vpc.id
  vpc_subnets       = local.subnets
  ssh_key_ids       = local.ssh_key_ids
  tags              = concat(var.tags, ["instance"])
}

#
# Retrieve all VPC instances -- if using an existing VPC
#
data "ibm_is_instances" "instances" {
  count = var.existing_vpc_name != "" ? 1 : 0

  vpc_name = var.existing_vpc_name
}

#
# Make sure to exclude the bastion
#
locals {
  instances = var.existing_vpc_name != "" ? [
    for instance in data.ibm_is_instances.instances.0.instances :
    instance if instance.id != module.bastion.bastion_id
  ] : (local.create_one_instance ? module.instance.0.instances : [])
}

#
# A bastion to host OpenVPN
#
module "bastion" {
  source  = "we-work-in-the-cloud/vpc-bastion/ibm"
  version = "0.0.7"

  name              = "${var.basename}-bastion"
  resource_group_id = local.resource_group_id
  vpc_id            = local.vpc.id
  subnet_id         = local.bastion_subnet_id
  ssh_key_ids       = local.ssh_key_ids
  tags              = concat(var.tags, ["bastion"])
}

# open the VPN port on the bastion
resource "ibm_is_security_group_rule" "vpn" {
  group     = module.bastion.bastion_security_group_id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  udp {
    port_min = 65000
    port_max = 65000
  }
}

#
# Allow all hosts created by this script to be accessible by the bastion
#
resource "ibm_is_security_group_target" "under_maintenance" {
  count             = local.create_one_instance ? length(module.instance.0.instances) : 0
  target            = module.instance.0.instances[count.index].primary_network_interface.0.id
  security_group    = module.bastion.bastion_maintenance_group_id
}

#
# Ansible playbook to install OpenVPN
#
module "ansible" {
  source     = "./ansible"
  bastion_ip = module.bastion.bastion_public_ip
  instances  = local.instances
  # the subnets are all subnets linked to the VPC created by this template
  # (or the existing VPC) plus all subnets from the additional VPC list.
  subnets = [
    for subnet in data.ibm_is_subnets.existing_subnets.0.subnets :
    subnet if subnet.vpc == local.vpc.id || contains(var.additional_vpc_ids_to_route_to, subnet.vpc)
  ]
  private_key_pem        = tls_private_key.ssh.private_key_pem
  openvpn_server_network = var.openvpn_server_network
  client_name            = var.basename
  additional_routes      = var.additional_routes
}

module "vpes" {
  count = tobool(var.create_vpe_for_ibmcloud_api) ? 1 : 0

  source            = "./vpes"
  basename          = var.basename
  resource_group_id = local.resource_group_id
  vpc_id            = local.vpc.id
  subnet_id         = local.bastion_subnet_id
}
