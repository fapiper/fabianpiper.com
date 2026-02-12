terraform {
  required_version = "~> 1.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 6.0"
    }
    context = {
      source  = "cloudposse/context"
      version = "~> 0.4"
    }
  }
}