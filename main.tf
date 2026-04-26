provider "aws" {
    region = "ap-south-1"
}
variable vpc_cidr_block{}
variable subnet_cidr_block{}
variable "avail_zone" {}
variable env_prefix {}
variable "my_ip" {}
variable "instance_type" {}
variable "public_key_path" {}

resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${var.env_prefix}-vpc"
  }
  
}

resource "aws_subnet" "myapp-subnet-1" {
    vpc_id = aws_vpc.myapp-vpc.id 
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
    tags = {
        Name = "${var.env_prefix}-subnet-1"
    }
  
}

resource "aws_internet_gateway" "myapp-igw" {
    vpc_id = aws_vpc.myapp-vpc.id
    tags = {
        Name = "${var.env_prefix}-igw"
    }
}

resource "aws_route_table" "myapp-route-table" {
    vpc_id = aws_vpc.myapp-vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id

    }
    tags = {
        Name = "${var.env_prefix}-rt"
    }
}

resource "aws_route_table_association" "assoc_subnet1" {
    subnet_id = aws_subnet.myapp-subnet-1.id
    route_table_id = aws_route_table.myapp-route-table.id
  
}

resource "aws_security_group" "myapp-sg" {
    name = "${var.env_prefix}-sg"
    description = "Security group for ${var.env_prefix} environment"
    vpc_id = aws_vpc.myapp-vpc.id
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.my_ip]
    }
    tags = {
        Name = "${var.env_prefix}-sg"
    }

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        prefix_list_ids = []
    }
}

data "aws_ami" "amazon_linux_2" {
    most_recent = true
    filter {
        name = "name"
        values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
    owners = ["amazon"]
}

resource "aws_key_pair" "kp_tf" {
    key_name = "kp_tf"
    public_key = file(var.public_key_path)
}

resource "aws_instance" "myapp-ec2-server" {
    ami                         = data.aws_ami.amazon_linux_2.id
    instance_type               = var.instance_type
    subnet_id                   = aws_subnet.myapp-subnet-1.id
    vpc_security_group_ids      = [aws_security_group.myapp-sg.id]
    associate_public_ip_address = true
    availability_zone           = var.avail_zone 

    key_name = aws_key_pair.kp_tf.key_name 

    tags = {
        Name = "${var.env_prefix}-ec2"
    }

    user_data = <<-EOF
                #!/bin/bash
                yum update -y
                yum install -y docker

                systemctl start docker
                systemctl enable docker

                usermod -aG docker ec2-user

                docker run -d -p 8080:80 nginx
            EOF
}

output "aws_instance_public_ip" {
    value = aws_instance.myapp-ec2-server.public_ip
}