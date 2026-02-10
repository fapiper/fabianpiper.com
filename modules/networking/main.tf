locals {
  enabled = var.enabled

  compartment_ocid = var.compartment_ocid
  vcn_cidr_blocks  = var.vcn_cidr_blocks
  vcn_dns_label    = var.vcn_dns_label

  subnet_cidr_block = var.subnet_cidr_block
  subnet_dns_label  = var.subnet_dns_label
}

data "context_config" "main" {}

data "context_label" "vcn" {
  values = {
    name = "vcn"
  }
}

data "context_tags" "vcn" {
  values = {
    name = "vcn"
  }
}

data "context_label" "subnet" {
  values = {
    name = var.subnet_name
  }
}

data "context_tags" "subnet" {
  values = {
    name = var.subnet_name
  }
}

resource "oci_core_vcn" "default" {
  count = local.enabled ? 1 : 0

  compartment_id = local.compartment_ocid
  cidr_blocks    = local.vcn_cidr_blocks
  display_name   = data.context_label.vcn.rendered
  dns_label      = local.vcn_dns_label
  freeform_tags  = data.context_tags.vcn.tags
}

resource "oci_core_internet_gateway" "default" {
  count = local.enabled ? 1 : 0

  compartment_id = local.compartment_ocid
  vcn_id         = oci_core_vcn.default[0].id
  display_name   = data.context_label.vcn.rendered
  enabled        = true
  freeform_tags  = data.context_tags.vcn.tags
}

resource "oci_core_default_route_table" "default" {
  count = local.enabled ? 1 : 0

  manage_default_resource_id = oci_core_vcn.default[0].default_route_table_id
  compartment_id             = local.compartment_ocid
  display_name               = data.context_label.vcn.rendered
  freeform_tags              = data.context_tags.vcn.tags
}

resource "oci_core_default_security_list" "internal" {
  count = local.enabled ? 1 : 0

  manage_default_resource_id = oci_core_vcn.default[0].default_security_list_id
  compartment_id             = local.compartment_ocid
  freeform_tags              = data.context_tags.vcn.tags
}


resource "oci_core_subnet" "default" {
  count = local.enabled ? 1 : 0

  compartment_id = local.compartment_ocid
  vcn_id         = oci_core_vcn.default[0].id
  cidr_block     = local.subnet_cidr_block
  display_name   = data.context_label.subnet.rendered
  dns_label      = local.subnet_dns_label
  freeform_tags  = data.context_tags.subnet.tags

  security_list_ids = [
    oci_core_security_list.ssh_ipv4[0].id,
    oci_core_security_list.node_ipv4[0].id,
    oci_core_security_list.container_cluster_ipv4[0].id
  ]
}

resource "oci_core_route_table" "default" {
  count = local.enabled ? 1 : 0

  compartment_id = local.compartment_ocid
  vcn_id         = oci_core_vcn.default[0].id
  display_name   = data.context_label.subnet.rendered
  freeform_tags  = data.context_tags.subnet.tags

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.default[0].id
  }
}

resource "oci_core_route_table_attachment" "default" {
  count = local.enabled ? 1 : 0

  subnet_id      = oci_core_subnet.default[0].id
  route_table_id = oci_core_route_table.default[0].id
}

resource "oci_core_security_list" "ssh_ipv4" {
  count = local.enabled ? 1 : 0

  compartment_id = local.compartment_ocid
  vcn_id         = oci_core_vcn.default[0].id
  display_name   = "${data.context_label.subnet.rendered}-ssh-ipv4"
  freeform_tags  = data.context_tags.subnet.tags

  # Allow all egress - simpler and more reliable
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
    description = "Allow all egress"
  }

  ingress_security_rules {
    source      = "0.0.0.0/0"
    protocol    = "6"  # TCP
    description = "Allow SSH ingress"

    tcp_options {
      min = 22
      max = 22
    }
  }

  # Allow HTTP ingress
  ingress_security_rules {
    source      = "0.0.0.0/0"
    protocol    = "6"  # TCP
    description = "Allow HTTP ingress"

    tcp_options {
      min = 80
      max = 80
    }
  }

  # Allow HTTPS ingress
  ingress_security_rules {
    source      = "0.0.0.0/0"
    protocol    = "6"  # TCP
    description = "Allow HTTPS ingress"

    tcp_options {
      min = 443
      max = 443
    }
  }

  # Allow internal VCN traffic
  ingress_security_rules {
    source      = "10.0.0.0/16"
    protocol    = "all"
    description = "Allow all internal VCN traffic"
  }
}

resource "oci_core_security_list" "node_ipv4" {
  count = local.enabled ? 1 : 0

  compartment_id = local.compartment_ocid
  vcn_id         = oci_core_vcn.default[0].id
  display_name   = "${data.context_label.subnet.rendered}-node-ipv4"
  freeform_tags  = data.context_tags.subnet.tags

  # Allow all egress
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
    description = "Allow all egress"
  }

  # Allow HTTPS ingress
  ingress_security_rules {
    source      = "0.0.0.0/0"
    protocol    = "6"  # TCP
    description = "Allow HTTPS ingress"

    tcp_options {
      min = 443
      max = 443
    }
  }

  # Allow HTTP ingress
  ingress_security_rules {
    source      = "0.0.0.0/0"
    protocol    = "6"  # TCP
    description = "Allow HTTP ingress"

    tcp_options {
      min = 80
      max = 80
    }
  }
}

resource "oci_core_security_list" "container_cluster_ipv4" {
  count = local.enabled ? 1 : 0

  compartment_id = local.compartment_ocid
  vcn_id         = oci_core_vcn.default[0].id
  display_name   = "${data.context_label.subnet.rendered}-container-cluster-ipv4"
  freeform_tags  = data.context_tags.subnet.tags

  # Allow all egress
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
    description = "Allow all egress"
  }

  # K3s API ingress
  ingress_security_rules {
    source      = "0.0.0.0/0"
    protocol    = "6"  # TCP
    description = "Allow K3s API ingress"

    tcp_options {
      min = 6443
      max = 6443
    }
  }

  # Allow all internal VCN traffic
  ingress_security_rules {
    source      = "10.0.0.0/16"
    protocol    = "all"
    description = "Allow all internal VCN traffic"
  }
}