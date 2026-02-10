# Networking Module
# Combines VCN and Subnets into a single, cohesive module

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

#----------------------------------------------------------------
# VCN Resources
#----------------------------------------------------------------

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

data "oci_core_vcn_dns_resolver_association" "default" {
  count = local.enabled ? 1 : 0

  vcn_id = oci_core_vcn.default[0].id
}

data "oci_dns_resolver" "default" {
  count = local.enabled ? 1 : 0

  resolver_id = data.oci_core_vcn_dns_resolver_association.default[0].dns_resolver_id
  scope       = "PRIVATE"
}

resource "oci_dns_resolver" "default" {
  count = local.enabled ? 1 : 0

  resolver_id  = data.oci_dns_resolver.default[0].id
  display_name = data.context_label.vcn.rendered
  freeform_tags = data.context_tags.vcn.tags
}

#----------------------------------------------------------------
# Subnet Resources
#----------------------------------------------------------------

resource "oci_core_subnet" "default" {
  count = local.enabled ? 1 : 0

  compartment_id = local.compartment_ocid
  vcn_id         = oci_core_vcn.default[0].id
  cidr_block     = local.subnet_cidr_block
  display_name   = data.context_label.subnet.rendered
  dns_label      = local.subnet_dns_label
  freeform_tags  = data.context_tags.subnet.tags
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

# Security Lists for K3s

resource "oci_core_security_list" "ssh_ipv4" {
  count = local.enabled ? 1 : 0

  compartment_id = local.compartment_ocid
  vcn_id         = oci_core_vcn.default[0].id
  display_name   = "${data.context_label.subnet.rendered}-ssh-ipv4"
  freeform_tags  = data.context_tags.subnet.tags

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "6"  # TCP
    stateless   = true
    description = "Allow SSH egress"

    tcp_options {
      source_port_range {
        min = 22
        max = 22
      }
    }
  }

  ingress_security_rules {
    source      = "0.0.0.0/0"
    protocol    = "6"  # TCP
    stateless   = true
    description = "Allow SSH ingress"

    tcp_options {
      min = 22
      max = 22
    }
  }
}

resource "oci_core_security_list" "node_ipv4" {
  count = local.enabled ? 1 : 0

  compartment_id = local.compartment_ocid
  vcn_id         = oci_core_vcn.default[0].id
  display_name   = "${data.context_label.subnet.rendered}-node-ipv4"
  freeform_tags  = data.context_tags.subnet.tags

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "6"  # TCP
    stateless   = true
    description = "Allow HTTPS egress"

    tcp_options {
      min = 443
      max = 443
    }
  }

  ingress_security_rules {
    source      = "0.0.0.0/0"
    protocol    = "6"  # TCP
    stateless   = true
    description = "Allow HTTPS ingress"

    tcp_options {
      source_port_range {
        min = 443
        max = 443
      }
    }
  }
}

resource "oci_core_security_list" "container_cluster_ipv4" {
  count = local.enabled ? 1 : 0

  compartment_id = local.compartment_ocid
  vcn_id         = oci_core_vcn.default[0].id
  display_name   = "${data.context_label.subnet.rendered}-container-cluster-ipv4"
  freeform_tags  = data.context_tags.subnet.tags

  # DNS egress (UDP)
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "17"  # UDP
    stateless   = true
    description = "Allow DNS egress"

    udp_options {
      min = 53
      max = 53
    }
  }

  # DNS egress (TCP)
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "6"  # TCP
    stateless   = true
    description = "Allow DNS egress"

    tcp_options {
      min = 53
      max = 53
    }
  }

  # K3s API egress
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "6"  # TCP
    stateless   = true
    description = "Allow container cluster API egress"

    tcp_options {
      source_port_range {
        min = 6443
        max = 6443
      }
    }
  }

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "6"  # TCP
    stateless   = true
    description = "Allow container cluster API requests egress"

    tcp_options {
      min = 6443
      max = 6443
    }
  }

  # etcd egress
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "6"  # TCP
    stateless   = true
    description = "Allow container cluster key value store egress"

    tcp_options {
      source_port_range {
        min = 2379
        max = 2380
      }
    }
  }

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "6"  # TCP
    stateless   = true
    description = "Allow container cluster key value store requests egress"

    tcp_options {
      min = 2379
      max = 2380
    }
  }

  # DNS ingress (UDP)
  ingress_security_rules {
    source      = "0.0.0.0/0"
    protocol    = "17"  # UDP
    stateless   = true
    description = "Allow DNS ingress"

    udp_options {
      source_port_range {
        min = 53
        max = 53
      }
    }
  }

  # DNS ingress (TCP)
  ingress_security_rules {
    source      = "0.0.0.0/0"
    protocol    = "6"  # TCP
    stateless   = true
    description = "Allow DNS ingress"

    tcp_options {
      source_port_range {
        min = 53
        max = 53
      }
    }
  }

  # K3s API ingress
  ingress_security_rules {
    source      = "0.0.0.0/0"
    protocol    = "6"  # TCP
    stateless   = true
    description = "Allow container cluster API ingress"

    tcp_options {
      min = 6443
      max = 6443
    }
  }

  ingress_security_rules {
    source      = "0.0.0.0/0"
    protocol    = "6"  # TCP
    stateless   = true
    description = "Allow container cluster API requests ingress"

    tcp_options {
      source_port_range {
        min = 6443
        max = 6443
      }
    }
  }

  # etcd ingress
  ingress_security_rules {
    source      = "0.0.0.0/0"
    protocol    = "6"  # TCP
    stateless   = true
    description = "Allow container cluster key value store ingress"

    tcp_options {
      min = 2379
      max = 2380
    }
  }

  ingress_security_rules {
    source      = "0.0.0.0/0"
    protocol    = "6"  # TCP
    stateless   = true
    description = "Allow container cluster key value store requests ingress"

    tcp_options {
      source_port_range {
        min = 2379
        max = 2380
      }
    }
  }
}

