locals {
  vpc_id = var.vpc_name == "" ? module.vpc.0.vpc.id : data.ibm_is_vpc.vpc.0.id
  vpc_resource_group_id = var.vpc_name == "" ? ibm_resource_group.group.0.id : data.ibm_is_vpc.vpc.0.resource_group
  vpc_subnets = var.vpc_name == "" ? module.vpc.0.subnets : data.ibm_is_subnet.subnet
  vpc_instances = var.vpc_name == "" ? module.instance.0.instances : [ for instance in data.ibm_is_instances.instances.0.instances : instance if instance.vpc == local.vpc_id && instance.id != module.bastion.instance.id ]
  ssh_key_ids = var.vpc_ssh_key_name != "" ? [data.ibm_is_ssh_key.sshkey[0].id, ibm_is_ssh_key.generated_key.id] : [ibm_is_ssh_key.generated_key.id]
}

# a resource group to put all the resources created in this template
# if an existing VPC name was specified, the resource group of the VPC will be used
resource ibm_resource_group group {
  count = var.vpc_name == "" ? 1 : 0
  name = "${var.basename}-group"
  tags = var.tags
}

# an optional SSH key to inject in virtual servers
data ibm_is_ssh_key sshkey {
  count = var.vpc_ssh_key_name != "" ? 1 : 0
  name  = var.vpc_ssh_key_name
}

# a generated key to inject in virtual servers
# used to deploy software on the servers
resource tls_private_key ssh {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource ibm_is_ssh_key generated_key {
  name           = "${var.basename}-${var.region}-key"
  public_key     = tls_private_key.ssh.public_key_openssh
  resource_group = local.vpc_resource_group_id
  tags           = concat(var.tags, ["vpc"])
}

# create a VPC to put the instances
# unless an existing VPC name was specified
module vpc {
  count = var.vpc_name == "" ? 1 : 0
  source            = "./vpc"
  name              = "${var.basename}-vpc"
  region            = var.region
  cidr_blocks       = ["10.10.10.0/24"]
  resource_group_id = ibm_resource_group.group.0.id
  tags              = var.tags
}

# an instance deployed in the VPC to test the setup
# unless an existing VPC name was specified
module instance {
  count = var.vpc_name == "" ? 1 : 0
  source = "./instance"
  name = "${var.basename}-instance"  
  resource_group_id = module.vpc.0.vpc.resource_group
  vpc_id = module.vpc.0.vpc.id
  vpc_subnets = module.vpc.0.subnets
  ssh_key_ids = local.ssh_key_ids
  tags = concat(var.tags, ["instance"])
}

# or load an existing VPC, subnets and instances
data ibm_is_vpc vpc {
  count = var.vpc_name == "" ? 0 : 1
  name = var.vpc_name
}

data ibm_is_subnet subnet {
  count = var.vpc_name == "" ? 0 : length(data.ibm_is_vpc.vpc.0.subnets)
  identifier = data.ibm_is_vpc.vpc.0.subnets[count.index].id
}

data ibm_is_instances instances {
  count = var.vpc_name == "" ? 0 : 1
}

# the bastion host where the VPN will be installed
module bastion {
  source = "./bastion"

  name = "${var.basename}-bastion"
  resource_group_id = local.vpc_resource_group_id
  vpc_id = local.vpc_id
  vpc_subnet = local.vpc_subnets.0
  ssh_key_ids = local.ssh_key_ids
  tags = concat(var.tags, ["bastion"])
}

# resource "ibm_is_security_group_network_interface_attachment" "under_maintenance" {
#   for_each          = toset(local.vpc_instances)
#   network_interface = each.value.primary_network_interface.0.id
#   security_group    = module.bastion.maintenance_group_id
# }

output bastion_ip {
  value = module.bastion.bastion_ip
}

output instance_ips {
  value = [
    for instance in local.vpc_instances : instance.primary_network_interface.0.primary_ipv4_address
  ]
}

module ansible {
  source = "./ansible"
  bastion_ip = module.bastion.bastion_ip
  instances = local.vpc_instances
  subnets = local.vpc_subnets
  private_key_pem = tls_private_key.ssh.private_key_pem
  server_network = var.server_network
}