############################################
# VPC Outputs
############################################

output "vpc-vpc_id" {
  value = module.project_vpc.vpc_id
}

output "vpc-name" {
  value = module.project_vpc.name
}

output "vpc-vpc_cidr_block" {
  value = module.project_vpc.vpc_cidr_block
}

output "vpc-azs" {
  value = module.project_vpc.azs
}

output "vpc-private_subnets" {
  value = module.project_vpc.private_subnets
}

output "vpc-private_subnets_cidr_blocks" {
  value = module.project_vpc.private_subnets_cidr_blocks
}

output "vpc-natgw_ids" {
  value = module.project_vpc.natgw_ids
}

output "vpc-endpoints_sg" {
  value = module.vpc_endpoints.security_group_id
}
