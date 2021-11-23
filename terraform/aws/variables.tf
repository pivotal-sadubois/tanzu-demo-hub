# variables.tf
 
# Variables for general information
######################################
 
variable "aws_region" {
  description = "AWS region"
  type        = string
  #default     = var.aws_region
}
 
variable "owner" {
  description = "TDH Environment"
  type        = string
  #default     = var.tdh_envronment
}
 
variable "aws_region_az" {
  description = "AWS region availability zone"
  type        = string
  #default     = var.availability_zone
}
 
 
# Variables for VPC
######################################
 
variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}
 
variable "vpc_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}
 
variable "vpc_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}
 
 
# Variables for Security Group
######################################
 
variable "sg_ingress_proto" {
  description = "Protocol used for the ingress rule"
  type        = string
  default     = "tcp"
}
 
variable "sg_ingress_ssh" {
  description = "Port used for the ingress rule"
  type        = string
  default     = "22"
}

variable "sg_ingress_ldap" {
  description = "Port used for the ingress rule"
  type        = string
  default     = "389"
}

variable "sg_ingress_ldaps" {
  description = "Port used for the ingress rule"
  type        = string
  default     = "636"
}

variable "sg_ingress_http" {
  description = "Port used for the ingress rule"
  type        = string
  default     = "80"
}

variable "sg_ingress_https" {
  description = "Port used for the ingress rule"
  type        = string
  default     = "443"
}

 
variable "sg_egress_proto" {
  description = "Protocol used for the egress rule"
  type        = string
  default     = "-1"
}
 
variable "sg_egress_all" {
  description = "Port used for the egress rule"
  type        = string
  default     = "0"
}
 
variable "sg_ingress_cidr_block" {
  description = "CIDR block for the egress rule"
  type        = string
  default     = "0.0.0.0/0"
}

variable "sg_egress_cidr_block" {
  description = "CIDR block for the egress rule"
  type        = string
  default     = "0.0.0.0/0"
}
 
 
# Variables for Subnet
######################################
 
variable "sbn_public_ip" {
  description = "Assign public IP to the instance launched into the subnet"
  type        = bool
  default     = true
}
 
variable "sbn_cidr_block" {
  description = "CIDR block for the subnet"
  type        = string
  default     = "10.0.1.0/24"
}
 
 
# Variables for Route Table
######################################
 
variable "rt_cidr_block" {
  description = "CIDR block for the route table"
  type        = string
  default     = "0.0.0.0/0"
}
 
 
# Variables for Instance
######################################
 
variable "instance_ami" {
  description = "ID of the AMI used"
  type        = string
  #default     = "ami-0211d10fb4a04824a"
  #Ubuntu 18.04 LTS - Bionic
  default     = "ami-075cd9bf9f73d75ca"
}
 
variable "instance_type" {
  description = "Type of the instance"
  type        = string
  default     = "t2.medium"
}
 
variable "key_pair" {
  description = "SSH Key pair used to connect"
  type        = string
  default     = "tanzu-demo-hub"
}
 
variable "root_device_type" {
  description = "Type of the root block device"
  type        = string
  default     = "gp2"
}
 
variable "root_device_size" {
  description = "Size of the root block device"
  type        = string
  default     = "50"
}
