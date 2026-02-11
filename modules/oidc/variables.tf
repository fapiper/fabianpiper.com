variable "tenancy_ocid" {
  type        = string
  description = "The OCID of the OCI tenancy"
}

variable "compartment_ocid" {
  type        = string
  description = "The OCID of the compartment where the policy will be created"
}

variable "user_ocid" {
  type        = string
  description = "The OCID of the OCI user that will be used by GitHub Actions"
}
