# create-vpc.tf
 
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = var.vpc_dns_hostnames
  enable_dns_support   = var.vpc_dns_support
 
  tags = {
    "Owner" = var.owner
    "Name"  = "${var.owner}-vpc"
  }
}
