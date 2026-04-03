module "dns" {
  source = "../../../modules/dns"

  enabled    = var.enabled
  zone_id    = var.zone_id
  ingress_ip = try(data.terraform_remote_state.cluster.outputs.ingress_public_ip, "")
  records    = var.records
}
