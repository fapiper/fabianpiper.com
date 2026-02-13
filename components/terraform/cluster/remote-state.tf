data "terraform_remote_state" "networking" {
  backend = "local"

  config = {
    path = "${path.module}/../networking/terraform.tfstate.d/${terraform.workspace}/terraform.tfstate"
  }
}

data "terraform_remote_state" "vault" {
  backend = "local"

  config = {
    path = "${path.module}/../vault/terraform.tfstate.d/${terraform.workspace}/terraform.tfstate"
  }
}
