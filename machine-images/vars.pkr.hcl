variable "tenancy_ocid" {
  type    = string
}

variable "user_ocid" {
  type    = string
}

variable "key_file" {
  type    = string
}

variable "fingerprint" {
  type    = string
}

variable "region" {
  type    = string
}

variable "k3s_version" {
  type    = string
  default = "v1.29.4+k3s1"
}

variable "k3s_token" {
  type = string
}

variable "subnet_ocid" {
  type = string
}

variable "availability_domain" {
  type    = string
}

variable "instance_ssh_private_key_file" {
  type = string
}

variable "skip_create_image" {
  type = bool
}
