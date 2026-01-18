module "project_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.0"

  name = "project_vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-2a", "eu-west-2b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_tags = {
    "Type" : "private"
  }
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_vpn_gateway = false
}

module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "6.6.0"

  vpc_id = module.project_vpc.vpc_id

  create_security_group = true

  security_group_name_prefix = "vpc-endpoints"
  security_group_description = "VPC endpoint security group"
  security_group_rules = {
    ingress_https = {
      description = "HTTPS from VPC CIDR"
      type        = "ingress"
      cidr_blocks = [module.project_vpc.vpc_cidr_block]
    },
  }

  endpoints = {
    s3 = {
      service             = "s3"
      private_dns_enabled = true
      dns_options = {
        private_dns_only_for_inbound_resolver_endpoint = false
      }
      subnet_ids = module.project_vpc.private_subnets
      tags = merge(var.common_tags, {
        Name : "s3-vpc-endpoint"
      })
    },
    ssm = {
      service             = "ssm"
      private_dns_enabled = true
      dns_options = {
        private_dns_only_for_inbound_resolver_endpoint = false
      }
      subnet_ids = module.project_vpc.private_subnets
      tags = merge(var.common_tags, {
        Name : "ssm-vpc-endpoint"
      })
    },
    ssmmessages = {
      service             = "ssmmessages"
      private_dns_enabled = true
      dns_options = {
        private_dns_only_for_inbound_resolver_endpoint = false
      }
      subnet_ids = module.project_vpc.private_subnets
      tags = merge(var.common_tags, {
        Name : "ssmmessages-vpc-endpoint"
      })
    },
    ec2 = {
      service             = "ec2"
      private_dns_enabled = true
      dns_options = {
        private_dns_only_for_inbound_resolver_endpoint = false
      }
      subnet_ids = module.project_vpc.private_subnets
      tags = merge(var.common_tags, {
        Name : "ec2-vpc-endpoint"
      })
    },
    ec2messages = {
      # N.B. Beginning with version 3.3.40.0 of SSM Agent, Systems Manager
      # began using the ssmmessages:* endpoint (Amazon Message Gateway
      # Service) whenever available instead of the ec2messages:* endpoint
      service             = "ec2messages"
      private_dns_enabled = true
      dns_options = {
        private_dns_only_for_inbound_resolver_endpoint = false
      }
      subnet_ids = module.project_vpc.private_subnets
      tags = merge(var.common_tags, {
        Name : "ec2messages-vpc-endpoint"
      })
    },
  }
}