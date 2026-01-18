module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.10.0"

  tags = merge(var.common_tags, {
    Name : "s3_bucket"
  })
}