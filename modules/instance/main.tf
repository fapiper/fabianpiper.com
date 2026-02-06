locals {
  enabled = data.context_config.main.enabled

  compartment_ocid = var.compartment_ocid
  name             = var.name
  subnet_id        = var.subnet_id
  shape            = var.shape
  public_key       = var.public_key
  load_balancers   = var.load_balancers

  vault_name              = var.vault_name
  secret_name             = var.secret_name
  k3s_version             = var.k3s_version
  k3s_token               = var.k3s_token
  internal_lb_domain_name = var.internal_lb_domain_name
}

data "context_config" "main" {}

data "context_label" "main" {
  values = {
    name = local.name
  }
}

data "context_tags" "main" {
  values = {
    name = local.name
  }
}

data "oci_core_images" "golden" {
  count = local.enabled ? 1 : 0

  compartment_id = local.compartment_ocid

  sort_by    = "TIMECREATED"
  sort_order = "DESC"

  filter {
    name = "display_name"
    values = [
      "^golden-image-([TZ0-9-:]+)$",
    ]
    regex = true
  }
}

data "oci_core_images" "default" {
  count = local.enabled ? 1 : 0

  compartment_id = local.compartment_ocid

  sort_by    = "TIMECREATED"
  sort_order = "DESC"

  filter {
    name = "display_name"
    values = [
      "^Canonical-Ubuntu-22.04-aarch64-([\\.0-9-]+)$",
    ]
    regex = true
  }
}

resource "oci_core_instance_configuration" "default" {
  count = local.enabled ? 1 : 0

  compartment_id = local.compartment_ocid
  display_name   = data.context_label.main.rendered

  instance_details {
    instance_type = "compute"

    launch_details {
      compartment_id = local.compartment_ocid

      instance_options {
        are_legacy_imds_endpoints_disabled = true
      }

      create_vnic_details {
        assign_private_dns_record = true
        assign_public_ip          = true
      }

      metadata = {
        ssh_authorized_keys = local.public_key
        user_data = base64encode(<<-EOT
            #!/usr/bin/env bash

            LOGFILE="/root/oci-user-data.log"
            exec 3>&1 4>&2 1>"$${LOGFILE}" 2>&1
            trap "echo 'ERROR: An error occurred during execution, check log $${LOGFILE} for details.' >&3" ERR
            trap '{ set +x; } 2>/dev/null; echo -n "[$(date -uIs)] "; set -x' DEBUG

            export COMPARTMENT_OCID="${local.compartment_ocid}"
            export VAULT_NAME="${local.vault_name}"
            export SECRET_NAME="${local.secret_name}"
            export K3S_VERSION="${local.k3s_version}"
            export K3S_TOKEN="${local.k3s_token}"
            export INTERNAL_LB_DOMAIN_NAME="${local.internal_lb_domain_name}"

            . /root/user-data.sh

          EOT
        )
      }

      shape = local.shape
      shape_config {
        memory_in_gbs = 6
        ocpus         = 1
      }

      is_pv_encryption_in_transit_enabled = true

      source_details {
        image_id = (length(data.oci_core_images.golden[0].images[*].id) != 0 ?
        data.oci_core_images.golden[0].images[0].id : data.oci_core_images.default[0].images[0].id)
        source_type = "image"
      }
    }
  }
  freeform_tags = data.context_tags.main.tags

  lifecycle {
    create_before_destroy = true
  }
}

data "oci_identity_availability_domains" "default" {
  count = local.enabled ? 1 : 0

  compartment_id = local.compartment_ocid
}

resource "oci_core_instance_pool" "default" {
  count = local.enabled ? 1 : 0

  display_name              = data.context_label.main.rendered
  compartment_id            = local.compartment_ocid
  instance_configuration_id = oci_core_instance_configuration.default[0].id
  size                      = length(data.oci_identity_availability_domains.default[0].availability_domains)

  dynamic "placement_configurations" {
    for_each = data.oci_identity_availability_domains.default[0].availability_domains
    content {
      availability_domain = placement_configurations.value.name
      primary_subnet_id   = local.subnet_id
    }
  }

  dynamic "load_balancers" {
    for_each = local.load_balancers
    content {
      load_balancer_id = load_balancers.value["id"]
      backend_set_name = load_balancers.value["backend_set_name"]
      port             = load_balancers.value["backend_port"]
      vnic_selection   = "PrimaryVnic"
    }
  }
  freeform_tags = data.context_tags.main.tags
}
