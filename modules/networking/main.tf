# OCI Networking Module - Main Configuration

locals {
  enabled = var.enabled
  name    = var.name
}

# VCN (Virtual Cloud Network)
resource "oci_core_vcn" "default" {
  count = local.enabled ? 1 : 0

  compartment_id = var.compartment_ocid
  cidr_block     = var.vcn_cidr_block
  display_name   = "${local.name}-vcn"
  dns_label      = var.vcn_dns_label
}

# Internet Gateway
resource "oci_core_internet_gateway" "default" {
  count = local.enabled ? 1 : 0

  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.default[0].id
  display_name   = "${local.name}-igw"
  enabled        = true
}

# Public Route Table
resource "oci_core_route_table" "public" {
  count = local.enabled ? 1 : 0

  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.default[0].id
  display_name   = "${local.name}-public-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.default[0].id
  }
}

# Public Security List
resource "oci_core_security_list" "public" {
  count = local.enabled ? 1 : 0

  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.default[0].id
  display_name   = "${local.name}-public-sl"

  # Egress: Allow all outbound
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  # Ingress: SSH
  ingress_security_rules {
    protocol = "6"  # TCP
    source   = var.ssh_source_cidr
    tcp_options {
      min = 22
      max = 22
    }
  }

  # Ingress: HTTP
  ingress_security_rules {
    protocol = "6"  # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 80
      max = 80
    }
  }

  # Ingress: HTTPS
  ingress_security_rules {
    protocol = "6"  # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 443
      max = 443
    }
  }

  # Ingress: K3s API
  ingress_security_rules {
    protocol = "6"  # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 6443
      max = 6443
    }
  }

  # Ingress: Allow all from VCN
  ingress_security_rules {
    protocol = "all"
    source   = var.vcn_cidr_block
  }
}

# Public Subnet
resource "oci_core_subnet" "public" {
  count = local.enabled ? 1 : 0

  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.default[0].id
  cidr_block                 = var.public_subnet_cidr
  display_name               = "${local.name}-public-subnet"
  dns_label                  = var.public_subnet_dns_label
  route_table_id             = oci_core_route_table.public[0].id
  security_list_ids          = [oci_core_security_list.public[0].id]
  prohibit_public_ip_on_vnic = false
}
