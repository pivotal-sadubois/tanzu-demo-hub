# create-sg.tf
 
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

resource "aws_security_group" "sg" {
  name        = "${var.owner}-sg"
  description = "Allow inbound traffic via SSH"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    "Owner" = var.owner
    "Name"  = "${var.owner}-sg"
  }
}

resource "aws_security_group_rule" "SSH" {
  type              = "ingress"
  protocol          = var.sg_ingress_proto
  from_port         = var.sg_ingress_ssh
  to_port           = var.sg_ingress_ssh
#  cidr_blocks       = ["${chomp(data.http.myip.body)}/32"]
  cidr_blocks       = [var.sg_egress_cidr_block]
  ipv6_cidr_blocks  = []
  security_group_id = aws_security_group.sg.id
}

resource "aws_security_group_rule" "LDAP" {
  type              = "ingress"
  protocol          = var.sg_ingress_proto
  from_port         = var.sg_ingress_ldap
  to_port           = var.sg_ingress_ldap
#  cidr_blocks       = ["${chomp(data.http.myip.body)}/32"]
  cidr_blocks       = [var.sg_egress_cidr_block]
  ipv6_cidr_blocks  = []
  security_group_id = aws_security_group.sg.id
}

resource "aws_security_group_rule" "LDAPS" {
  type              = "ingress"
  protocol          = var.sg_ingress_proto
  from_port         = var.sg_ingress_ldaps
  to_port           = var.sg_ingress_ldaps
#  cidr_blocks       = ["${chomp(data.http.myip.body)}/32"]
  cidr_blocks       = [var.sg_egress_cidr_block]
  ipv6_cidr_blocks  = []
  security_group_id = aws_security_group.sg.id
}

resource "aws_security_group_rule" "All" {
  type              = "egress"
  protocol          = var.sg_egress_proto
  from_port         = var.sg_egress_all
  to_port           = var.sg_egress_all
  cidr_blocks       = [var.sg_egress_cidr_block]
  ipv6_cidr_blocks  = []
  security_group_id = aws_security_group.sg.id
}

