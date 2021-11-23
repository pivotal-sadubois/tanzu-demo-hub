#create-sbn.tf
 
resource "aws_subnet" "subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.sbn_cidr_block
  map_public_ip_on_launch = var.sbn_public_ip
  availability_zone       = "${var.aws_region}${var.aws_region_az}"
 
  tags = {
    "Owner" = var.owner
    "Name"  = "${var.owner}-subnet"
  }
}
