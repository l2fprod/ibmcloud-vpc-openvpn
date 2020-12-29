terraform {
  required_version = ">= 0.13.2"

  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
      version = ">= 1.17"
    }
  }
}