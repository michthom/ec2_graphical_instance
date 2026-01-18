terraform {
  backend "s3" {
    key = "storage/terraform.tfstate"
  }
}