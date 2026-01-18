# File structure

Taken from https://developer.hashicorp.com/terraform/language/style#file-names

cd [TLD]/[layer]/terraform

terraform init -backend-config=../../backends/dev.tfbackend

terraform plan -var-file=../config/dev.tfvars# ec2_graphical_instance
