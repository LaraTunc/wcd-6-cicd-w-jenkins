terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.31.0"
    }
  }
}

variable "AWS_REGION" {}
variable "AWS_PROFILE" {}
variable "KEY_PAIR_NAME" {}
provider "aws" {
    region = var.AWS_REGION 
    profile =  var.AWS_PROFILE 
}

# Create an AWS VPC. 
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/24"

   tags = {
    Name = "eval-6-vpc",
  }
}

# Create an internet gateway and associate it to the VPC.
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "eval-6-igw",
  }
}


resource "aws_subnet" "public-subnet" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.0.64/26"
  
  tags = {
    Name = "eval-6-public-subnet",
  }
}

# Create a public route table routing 0.0.0.0/0 to the internet gateway.
resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "eval-6-public-subnet",
  }
}

# Associate the public subnet to the public route table. 
resource "aws_route_table_association" "public-subnet-association" {
  subnet_id = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.public-route-table.id
}

# Create security groups for the jenkins ec2 
# Public subnet security group allows incoming traffic on port 80, 443, 8080 from 0.0.0.0/0 (public internet). 
resource "aws_security_group" "public-subnet-sg" {
  name = "eval-6-public-subnet-sg"
  description = "Allow all incoming traffic from on port 80 and 443 from 0.0.0.0/0 (public internet)"
  vpc_id = aws_vpc.vpc.id

  ingress {
    description = "ssh"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "http from public internet"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "tcp from 8080"
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
    }

  tags = {
    Name = "eval-6-public-subnet-sg",
  }
}

# Create a sg for the deployment ec2
resource "aws_security_group" "deployment-sg" {
  name = "eval-6-deployment-sg"
  description = "Allow all incoming traffic from on port 80 and 443 from 0.0.0.0/0 (public internet)"
  vpc_id = aws_vpc.vpc.id

  ingress {
    description = "Allow all incoming traffic from public subnet security group"
    from_port = 0
    to_port = 0
    protocol = "-1"
    security_groups = [aws_security_group.public-subnet-sg.id]
  }

  ingress {
    description = "ssh"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "all traffic"
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }

  tags = {
    Name = "eval-6-deployment-sg",
  }
}

resource "aws_instance" "jenkins_ec2" {
  ami = "ami-0fc5d935ebf8bc3bc"
  instance_type = "t2.small"
  key_name = var.KEY_PAIR_NAME
  vpc_security_group_ids = [aws_security_group.public-subnet-sg.id]
  subnet_id = aws_subnet.public-subnet.id
  associate_public_ip_address = true
  user_data = file("./user_data/index.sh")

  tags = {
    Name = "jenkins_ec2",
  }
}

resource "aws_instance" "deployment_ec2" {
  ami = "ami-0fc5d935ebf8bc3bc"
  instance_type = "t2.small"
  key_name = var.KEY_PAIR_NAME
  vpc_security_group_ids = [aws_security_group.deployment-sg.id]
  subnet_id = aws_subnet.public-subnet.id
  associate_public_ip_address = true
  user_data = file("./user_data/deploy.sh")

  tags = {
    Name = "deployment_ec2",
  }
}
