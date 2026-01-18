# This works and locates the correct VPC [id=vpc-02af67fb991e1eeb5]
data "aws_vpc" "project_vpc" {
  filter {
    name   = "tag:Name"
    values = ["project_vpc"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.project_vpc.id]
  }
  filter {
    name   = "tag:Type"
    values = ["private"]
  }
}

data "aws_security_group" "endpoints" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.project_vpc.id]
  }
  filter {
    name   = "tag:Name"
    values = ["vpc-endpoints"]
  }
}

# Will need instance to have permimssion to check for DCV license
# https://docs.aws.amazon.com/dcv/latest/adminguide/setting-up-license.html

module "dcv_license_s3_policy" {
  source = "terraform-aws-modules/iam/aws//modules/iam-policy"

  name_prefix = "dcv-license-s3-"
  path        = "/"
  description = "Access to DCV license in S3"

  policy = <<-EOF
    {
      "Version":"2012-10-17",		 	 	 
      "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::dcv-license.eu-west-2/*"
        }
      ]
    }
  EOF

  tags = merge(var.common_tags, {
    Name : "vdi_iam_policy_dcv_license_s3"
  })
}

module "dcv_user_password_access_policy" {
  source = "terraform-aws-modules/iam/aws//modules/iam-policy"

  name_prefix = "dcv-secretsmgr-access-"
  path        = "/"
  description = "Access to DCV password in Secrets Manager"

  policy = <<-EOF
    {
      "Version":"2012-10-17",		 	 	 
      "Statement": [
        {
            "Effect": "Allow",
            "Action": "secretsmanager:GetSecretValue",
            "Resource": "${module.canary_instance_pw.password_secret_id}"
        }
      ]
    }
  EOF

  tags = merge(var.common_tags, {
    Name : "vdi_iam_policy_dcv_password"
  })
}

module "canary_instance_pw" {
  source      = "../../..//modules/randomised_password_secret"
  secret_name = "canary_instance/dcv_user_password"

}

module "canary_instance_userdata" {
  source = "../../..//modules/concatenate_templates"

  source_directory = "../config/userdata_scriptlets"
  file_list = [
    "000_header.tftpl",
    "010_update_dnf.tftpl",
    "020_ssm_agent.tftpl",
    "030_aws_cli.tftpl",
    "040_gnome_desktop.tftpl",
    "050_dcv_server.tftpl",
    "060_xdummy_driver.tftpl",
    "070_nginx_server.tftpl",
    "990_final_commands.tftpl",
    "999_footer.tftpl",
  ]

  template_vars = {
    DCV_USER_NAME   = "dcv-user"
    DCV_PASSWORD_ID = module.canary_instance_pw.password_secret_id
  }
}

module "canary_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "6.2.0"

  name          = "canary_instance"
  instance_type = "t3.small"

  # Rocky-9-EC2-Base-9.6-20250531.0.x86_64-3f230a17-9877-4b16-aa5e-b1ff34ab206b
  ami = "ami-05a5686f0de7aa5d5"

  create_iam_instance_profile = true
  iam_role_description        = "IAM role for EC2 instance - SSM, DCV, etc."
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    DCVLicenceS3Access           = module.dcv_license_s3_policy.arn
    DCVPasswordAccess            = module.dcv_user_password_access_policy.arn
  }

  create_security_group          = true
  security_group_name            = "canary_instance_sg"
  security_group_use_name_prefix = true
  security_group_ingress_rules   = {}
  security_group_egress_rules = {
    "ipv4_default" : {
      "cidr_ipv4" : "0.0.0.0/0",
      "description" : "Allow all IPv4 traffic",
      "ip_protocol" : "-1"
    },
    "ipv6_default" : {
      "cidr_ipv6" : "::/0",
      "description" : "Allow all IPv6 traffic",
      "ip_protocol" : "-1"
    },
  }

  subnet_id              = data.aws_subnets.private.ids[1]
  vpc_security_group_ids = []

  tags = merge(var.common_tags, {
    ProjectComponent : "VDI Instance"
  })

  user_data_replace_on_change = true

  user_data_base64 = module.canary_instance_userdata.concatenated_content_base64
}


module "vdi_instance_pw" {
  source          = "../../..//modules/randomised_password_secret"
  secret_name     = "vdi_instance/dcv_user_password"
  password_length = 16
}

module "vdi_instance_userdata" {
  source = "../../..//modules/concatenate_templates"

  source_directory = "../config/userdata_scriptlets"
  file_list = [
    "000_header.tftpl",
    "010_update_dnf.tftpl",
    "020_ssm_agent.tftpl",
    "030_aws_cli.tftpl",
    # FIXME - need the nvidia driver installation here
    "040_gnome_desktop.tftpl",
    "050_dcv_server.tftpl",
    "990_final_commands.tftpl",
    "999_footer.tftpl",
  ]

  template_vars = {
    DCV_USER_NAME   = "dcv-user"
    DCV_PASSWORD_ID = module.vdi_instance_pw.password_secret_id
  }
}

# module "vdi-instance" {
#   source  = "terraform-aws-modules/ec2-instance/aws"
#   version = "6.2.0"

#   name = "vdi-instance"

#   instance_type = "g4dn.xlarge"
#   # https://docs.aws.amazon.com/ec2/latest/instancetypes/ac.html
#   # 0.125 GPU (1/8 NVIDIA T4)
#   # 16GB GPU Memory
#   # 4 vCPU (Intel Xeon P-8259L - x86_64)
#   # 16GB RAM
#   # $0.615 / hour - expensive. Do I need a non-GPU instance and a non-accelerated X Server?

#   # Selecting g6f.xlarge type threw an error (now solved, see below)
#   #   Error: creating EC2 Instance: operation error EC2: RunInstances,
#   #   https response error StatusCode: 400, RequestID: 4f98b5f4-2404-4f54-adfc-0e8ac0e7b5f0,
#   #   api error VcpuLimitExceeded:
#   #   You have requested more vCPU capacity than your current vCPU limit of 0 allows for the
#   #   instance bucket that the specified instance type belongs to.
#   #   Please visit http://aws.amazon.com/contact-us/ec2-request to request an adjustment to this limit.

#   #   Had to go to Service Quotas / EC2 and search for "On-Demand" and "Spot Instance"
#   #   Requested increase from 0 to 8 for each.

#   #   Then tracked in Support / Support cases until done.

#   create_iam_instance_profile = true
#   iam_role_description        = "IAM role for EC2 instance - SSM, DCV, etc."
#   iam_role_policies = {
#     EC2RoleforSSM = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
#     DCVLicenseS3  = module.dcv_license_s3_policy.arn
#   }

#   create_security_group = true
#   security_group_name = "vdi_server_sg"
#   security_group_use_name_prefix = true
#   security_group_ingress_rules = {
#     dcv_from_ssm = {
#       from_port = 8443
#       to_port = 8443
#       ip_protocol = "tcp"
#       referenced_security_group_id = data.aws_security_group.endpoints.id
#     }
#     endpoint_comms = {
#       from_port = 443
#       to_port = 443
#       ip_protocol = "tcp"
#       referenced_security_group_id = data.aws_security_group.endpoints.id
#     }
#   }
#   security_group_egress_rules = {
#     "ipv4_default": {
#       "cidr_ipv4": "0.0.0.0/0",
#       "description": "Allow all IPv4 traffic",
#       "ip_protocol": "-1"
#     },
#     "ipv6_default": {
#       "cidr_ipv6": "::/0",
#       "description": "Allow all IPv6 traffic",
#       "ip_protocol": "-1"
#     },
#   }

#   iam_instance_profile = "EC2RoleForSSM"

#   subnet_id     = data.aws_subnets.private.ids[0]
#   vpc_security_group_ids = []

#   # DCV is free on AWS EC2
#   # https://aws.amazon.com/hpc/dcv/#:~:text=4K%20resolution%20each.-,Pricing

#   # Rocky 9.x x86-64 (Intel / AMD)
#   # aws ec2 describe-images --region eu-west-2 --owners aws-marketplace --filters 'Name=architecture,Values=x86_64' 'Name=name,Values=Rocky-9-EC2-Base-*' --query 'reverse(sort_by(Images, &CreationDate))[].[ImageId, Name]' 
#   # - - ami-05a5686f0de7aa5d5
#   #   - Rocky-9-EC2-Base-9.6-20250531.0.x86_64-3f230a17-9877-4b16-aa5e-b1ff34ab206b
#   # - - ami-082a19a0d820f7ad6
#   #   - Rocky-9-EC2-Base-9.5-20241118.0.x86_64-3f230a17-9877-4b16-aa5e-b1ff34ab206b
#   # - - ami-0d6fdacca4c48fc91
#   #   - Rocky-9-EC2-Base-9.4-20240523.0.x86_64-3f230a17-9877-4b16-aa5e-b1ff34ab206b

#   # aws ec2 describe-images --region eu-west-2 --owners aws-marketplace --filters 'Name=architecture,Values=x86_64' 'Name=name,Values=Rocky-9-EC2-Base-*' --query 'reverse(sort_by(Images, &CreationDate))[:1].ImageId' --output text
#   # ami-05a5686f0de7aa5d5

#   # Rocky-9-EC2-Base-9.6-20250531.0.x86_64-3f230a17-9877-4b16-aa5e-b1ff34ab206b
#   ami = "ami-05a5686f0de7aa5d5"

#   user_data_replace_on_change = true
#   user_data_base64 = module.vdi_instance_userdata.concatenated_content_base64

#   tags = merge(var.common_tags, {
#     Name: "vdi_instance"
#   })
# }
