provider "aws" {
    region = "ap-south-1"
  
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
  default = "10.0.0.0/16"
}

variable "private_subnet_cidr_blocks" {
   description = "The CIDR block for the private subnet"
   type        = list(string)
   default = [ "10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24" ]
}

variable "public_subnet_cidr_blocks" {
  description = "The CIDR block for the public subnet"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "myApp-vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "myApp-vpc"
  cidr = var.vpc_cidr_block

  azs             = data.aws_availability_zones.available.names
  private_subnets = var.private_subnet_cidr_blocks
  public_subnets  = var.public_subnet_cidr_blocks
 
  enable_nat_gateway = true
  single_nat_gateway = true
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    "Kubernetes.io/Cluster/myApp-eks-cluster" = "shared"
  }
  public_subnet_tags = {
    "Kubernetes.io/cluster/myApp-eks-cluster" = "shared"
    "Kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "Kubernetes.io/cluster/myApp-eks-cluster" = "shared"
    "Kubernetes.io/role/internal-elb " = "1"
  }
}