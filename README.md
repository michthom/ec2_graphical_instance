# EC2 Graphical Instance

Builds an EC2 instance using Rocky 9 in a private subnet.

## Components

* [CloudFormation bootstrap template](./boostrap/terraform-state-s3-bucket.yaml) to build a state bucket for Terraform to use.
* Infrastructure layers:
  * VPC with basic configuration [(network)](./infrastructure/network/)
  * S3 bucket [(storage)](./infrastructure/storage/)
  * Virtual desktop EC2 instance [(vdi)](./infrastructure/vdi/)
* Helper module
  * Userdata file concatenator [(concatenate_templates)](./modules/concatenate_templates/)

## Deployment steps
1. Build Cloudformation stack from the template to create the S3 state bucket.

2. Update the state bucket details in the [.tfbackend](./backends/) files.

3. Select the required configuration directory.
```
cd infrastructure/{configuration}/terraform
```
4. Initialise the terraform backend if needed.
```
terraform init -backend-config=../../backends/dev.tfbackend
```
5. Plan the deployment.
```
terraform plan -var-file=../config/dev.tfvars# ec2_graphical_instance
```
6. Deploy the infrastructure.
```
terraform apply -var-file=../config/dev.tfvars# ec2_graphical_instance
```