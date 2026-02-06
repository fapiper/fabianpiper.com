locals {
  enabled = data.context_config.main.enabled

  compartment_ocid          = var.compartment_ocid
  name                      = var.name
  vcn_id                    = var.vcn_id
  igw_id                    = var.igw_id
  default_security_list_id  = var.default_security_list_id
  ipv4_cidr_block           = var.ipv4_cidr_block
  dns_label                 = var.dns_label
  ssh_enabled               = local.enabled && var.ssh_enabled
  https_enabled             = local.enabled && var.https_enabled
  container_cluster_enabled = local.enabled && var.container_cluster_enabled
  create_route_table        = local.enabled && var.create_route_table
  route_table_enabled       = local.enabled && var.route_table_enabled
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

resource "oci_core_subnet" "default" {
  count = local.enabled ? 1 : 0

  compartment_id = local.compartment_ocid
  display_name   = data.context_label.main.rendered
  vcn_id         = local.vcn_id
  cidr_block     = local.ipv4_cidr_block
  dns_label      = local.dns_label
  security_list_ids = concat(
    [local.default_security_list_id],
    oci_core_security_list.ssh_ipv4[*].id,
    oci_core_security_list.node_ipv4[*].id,
    oci_core_security_list.container_cluster_ipv4[*].id,
  )
  freeform_tags = data.context_tags.main.tags
}

resource "oci_core_security_list" "ssh_ipv4" {
  count = local.ssh_enabled ? 1 : 0

  compartment_id = local.compartment_ocid
  vcn_id         = local.vcn_id
  display_name   = "${data.context_label.main.rendered}-ssh-ipv4"

  ingress_security_rules {
    source      = "0.0.0.0/0"
    protocol    = 6 # source: https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml
    stateless   = true
    description = "Allow SSH ingress"

    tcp_options {
      min = 22
      max = 22
    }
  }
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = 6 # source: https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml
    stateless   = true
    description = "Allow SSH egress"

    tcp_options {
      source_port_range {
        max = 22
        min = 22
      }
    }
  }
  freeform_tags = data.context_tags.main.tags
}

resource "oci_core_security_list" "node_ipv4" {
  count = local.https_enabled ? 1 : 0

  compartment_id = local.compartment_ocid
  vcn_id         = local.vcn_id
  display_name   = "${data.context_label.main.rendered}-node-ipv4"

  ingress_security_rules {
    source      = "0.0.0.0/0"
    protocol    = 6 # Source: https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml
    stateless   = true
    description = "Allow HTTPS ingress"

    tcp_options {
      source_port_range {
        max = 443
        min = 443
      }
    }
  }
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = 6 # Source: https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml
    stateless   = true
    description = "Allow HTTPS egress"

    tcp_options {
      max = 443
      min = 443
    }
  }
  freeform_tags = data.context_tags.main.tags
}

# Source: https://docs.k3s.io/installation/requirements#inbound-rules-for-k3s-nodes
resource "oci_core_security_list" "container_cluster_ipv4" {
  count = local.container_cluster_enabled ? 1 : 0

  compartment_id = local.compartment_ocid
  vcn_id         = local.vcn_id
  display_name   = "${data.context_label.main.rendered}-container-cluster-ipv4"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = 6 # Source: https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml
    stateless   = true
    description = "Allow container cluster API requests egress"

    tcp_options {
      max = 6443
      min = 6443
    }
  }
  ingress_security_rules {
    source      = "0.0.0.0/0"
    protocol    = 6 # Source: https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml
    stateless   = true
    description = "Allow container cluster API ingress"

    tcp_options {
      max = 6443
      min = 6443
    }
  }
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = 6 # Source: https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml
    stateless   = true
    description = "Allow container cluster API egress"

    tcp_options {
      source_port_range {
        max = 6443
        min = 6443
      }
    }
  }
  ingress_security_rules {
    source      = "0.0.0.0/0"
    protocol    = 6 # Source: https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml
    stateless   = true
    description = "Allow container cluster API requests ingress"

    tcp_options {
      source_port_range {
        max = 6443
        min = 6443
      }
    }
  }
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = 6 # Source: https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml
    stateless   = true
    description = "Allow container cluster key value store requests egress"

    tcp_options {
      max = 2380
      min = 2379
    }
  }
  ingress_security_rules {
    source      = "0.0.0.0/0"
    protocol    = 6 # Source: https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml
    stateless   = true
    description = "Allow container cluster key value store ingress"

    tcp_options {
      max = 2380
      min = 2379
    }
  }
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = 6 # Source: https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml
    stateless   = true
    description = "Allow container cluster key value store egress"

    tcp_options {
      source_port_range {
        max = 2380
        min = 2379
      }
    }
  }
  ingress_security_rules {
    source      = "0.0.0.0/0"
    protocol    = 6 # Source: https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml
    stateless   = true
    description = "Allow container cluster key value store requests ingress"

    tcp_options {
      source_port_range {
        max = 2380
        min = 2379
      }
    }
  }
  ingress_security_rules {
    source      = "0.0.0.0/0"
    protocol    = 6 # Source: https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml
    stateless   = true
    description = "Allow DNS ingress"

    tcp_options {
      source_port_range {
        max = 53
        min = 53
      }
    }
  }
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = 6 # Source: https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml
    stateless   = true
    description = "Allow DNS egress"

    tcp_options {
      max = 53
      min = 53
    }
  }
  ingress_security_rules {
    source      = "0.0.0.0/0"
    protocol    = 17 # Source: https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml
    stateless   = true
    description = "Allow DNS ingress"

    udp_options {
      source_port_range {
        max = 53
        min = 53
      }
    }
  }
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = 17 # Source: https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml
    stateless   = true
    description = "Allow DNS egress"

    udp_options {
      max = 53
      min = 53
    }
  }
  freeform_tags = data.context_tags.main.tags
}

resource "oci_core_route_table" "default" {
  count = local.create_route_table ? 1 : 0

  compartment_id = local.compartment_ocid
  display_name   = data.context_label.main.rendered
  vcn_id         = local.vcn_id

  route_rules {
    network_entity_id = local.igw_id
    destination       = "0.0.0.0/0"
  }
  freeform_tags = data.context_tags.main.tags
}

resource "oci_core_route_table_attachment" "default" {
  count = local.route_table_enabled ? 1 : 0

  subnet_id      = oci_core_subnet.default[0].id
  route_table_id = oci_core_route_table.default[0].id
}
