variable "basename" {}
variable "resource_group_id" {}
variable "vpc_id" {}
variable "subnet_id" {}

# these endpoints help to use the API through private connection when running within a VPC
locals {
  apis = [
    {
      id       = "account-management"
      endpoint = "private.accounts.cloud.ibm.com"
    },
    {
      id       = "iam-svcs"
      endpoint = "private.iam.cloud.ibm.com"
    },
    {
      id       = "billing"
      endpoint = "private.billing.cloud.ibm.com"
    },
    {
      id       = "enterprise"
      endpoint = "private.enterprise.cloud.ibm.com"
    },
    {
      id       = "globalcatalog"
      endpoint = "private.globalcatalog.cloud.ibm.com"
    },
    {
      id       = "resource-controller"
      endpoint = "private.resource-controller.cloud.ibm.com"
    },
    {
      id       = "ghost-tags"
      endpoint = "tags.private.global-search-tagging.cloud.ibm.com"
    },
    {
      id       = "user-management"
      endpoint = "private.user-management.cloud.ibm.com"
    }
  ]
}

resource "ibm_is_virtual_endpoint_gateway" "endpoint" {
  for_each = { for api in local.apis : api.id => api }

  name = "${var.basename}-${lower(each.value.id)}"
  target {
    crn           = "crn:v1:bluemix:public:${each.value.id}:global:::endpoint:${each.value.endpoint}"
    resource_type = "provider_cloud_service"
  }
  ips {
    name   = "${var.basename}-${lower(each.value.id)}-ip"
    subnet = var.subnet_id
  }
  vpc            = var.vpc_id
  resource_group = var.resource_group_id
}
