resource "oci_network_load_balancer_network_load_balancer" "k3s_nlb" {
  compartment_id = var.compartment_ocid
  display_name   = "k3s-nlb"
  subnet_id      = var.public_subnet_id

  is_private                     = false
  is_preserve_source_destination = false

  freeform_tags = var.common_tags
}

# HTTP Backend Set
resource "oci_network_load_balancer_backend_set" "k3s_backend_set_http" {
  name                     = "k3s-backend-set-http"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.k3s_nlb.id
  policy                   = "FIVE_TUPLE"

  health_checker {
    protocol           = "TCP"
    port               = 80
    interval_in_millis = 10000
    timeout_in_millis  = 3000
    retries            = 3
  }
}

resource "oci_network_load_balancer_backend" "ingress_backend_http" {
  backend_set_name         = oci_network_load_balancer_backend_set.k3s_backend_set_http.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.k3s_nlb.id
  port                     = 80
  target_id                = var.ingress_instance_id
}

resource "oci_network_load_balancer_listener" "http_listener" {
  name                     = "http-listener"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.k3s_nlb.id
  default_backend_set_name = oci_network_load_balancer_backend_set.k3s_backend_set_http.name
  port                     = 80
  protocol                 = "TCP"
}

# HTTPS Backend Set
resource "oci_network_load_balancer_backend_set" "k3s_backend_set_https" {
  name                     = "k3s-backend-set-https"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.k3s_nlb.id
  policy                   = "FIVE_TUPLE"

  health_checker {
    protocol           = "TCP"
    port               = 443
    interval_in_millis = 10000
    timeout_in_millis  = 3000
    retries            = 3
  }
}

resource "oci_network_load_balancer_backend" "ingress_backend_https" {
  backend_set_name         = oci_network_load_balancer_backend_set.k3s_backend_set_https.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.k3s_nlb.id
  port                     = 443
  target_id                = var.ingress_instance_id
}

resource "oci_network_load_balancer_listener" "https_listener" {
  name                     = "https-listener"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.k3s_nlb.id
  default_backend_set_name = oci_network_load_balancer_backend_set.k3s_backend_set_https.name
  port                     = 443
  protocol                 = "TCP"
}
