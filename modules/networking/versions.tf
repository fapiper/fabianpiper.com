terraform {
  required_version = ">= 1.3"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 6.0.0"
    }
    context = {
      source  = "cloudposse/context"
      version = ">= 0.4.0"
    }
  }
}

