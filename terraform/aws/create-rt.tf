#create-rt.tf
 
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id
 
  route {
    cidr_block = var.rt_cidr_block
    gateway_id = aws_internet_gateway.igw.id
  }
 
  tags = {
    "Owner" = var.owner
    "Name"  = "${var.owner}-rt"
  }
}

resource "aws_route_table_association" "rt_sbn_asso" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.rt.id
}
