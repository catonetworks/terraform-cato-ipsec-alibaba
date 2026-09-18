terraform {
  required_providers {
    cato = {
      source  = "catonetworks/cato"
      version = ">= 0.0.69"
    }
    alicloud = {
      source  = "aliyun/alicloud"
      version = ">= 1.293.0, < 2.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
  required_version = ">= 1.5"
}
