data "terraform_remote_state" "networking" {
  backend = "local"

  config = {
    path = "${path.module}/../networking/terraform.tfstate.d/${terraform.workspace}/terraform.tfstate"
  }
}

