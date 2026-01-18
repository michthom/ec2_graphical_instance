# All provider blocks

provider "aws" {
  region = "eu-west-2"

  default_tags {
    tags = {
      ProjectName : "MyAwesomeProject"
    }
  }
}