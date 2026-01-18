terraform {
  backend "s3" {
    key = "workspaces/terraform.tfstate"
  }
}