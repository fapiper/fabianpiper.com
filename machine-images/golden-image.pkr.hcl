packer {
  required_plugins {
    oracle = {
      source  = "github.com/hashicorp/oracle"
      version = "~> 1.0"
    }
  }
}

source "oracle-oci" "server" {
  tenancy_ocid = var.tenancy_ocid
  user_ocid    = var.user_ocid
  key_file     = var.key_file
  fingerprint  = var.fingerprint
  region       = var.region

  availability_domain = var.availability_domain

  base_image_filter {
    display_name_search = "^Canonical-Ubuntu-22.04-aarch64-([\\.0-9-]+)$"
  }

  compartment_ocid     = var.tenancy_ocid
  image_name           = "golden-image-${timestamp()}"
  shape                = "VM.Standard.A1.Flex"
  ssh_private_key_file = var.instance_ssh_private_key_file
  ssh_username         = "ubuntu"
  subnet_ocid          = var.subnet_ocid
  shape_config {
    memory_in_gbs = 6
    ocpus         = 1
  }
  skip_create_image = var.skip_create_image
}

build {
  sources = [
    "source.oracle-oci.server",
  ]

  provisioner "file" {
    source      = "machine-images/scripts/create-server-golden-image.sh"
    destination = "~/create-server-golden-image.sh"
  }

  provisioner "file" {
    source      = "machine-images/scripts/user-data.sh"
    destination = "~/user-data.sh"
  }

  provisioner "shell" {
    execute_command = "sudo bash -c '{{ .Vars }} {{ .Path }}'"
    scripts = [
      "machine-images/scripts/create-server-golden-image.sh",
    ]
  }
}
