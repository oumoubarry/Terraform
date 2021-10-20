provider "aws"{
  region =  var.aws_region
}
resource "aws_vpc" "terra-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "terra-vpc"

  }
}
  # creating the igw 
resource "aws_internet_gateway" "terra-igw" {
  vpc_id = aws_vpc.terra-vpc.id

  tags = {
    Name = "terra-igw"
  }
}

  #  Public subnet 
resource "aws_subnet" "terra-pub-sub1" {
  vpc_id                  = aws_vpc.terra-vpc.id
  cidr_block              = var.pub_sub1_cidr_block
  availability_zone       = var.az_number
  map_public_ip_on_launch = true

  tags = {
    Name = "terra-pub-sub1"
  }
}
  #  Private subnet 
resource "aws_subnet" "terra-priv-sub1" {
  vpc_id                  = aws_vpc.terra-vpc.id
  cidr_block              = var.priv_sub1_cidr_block
  availability_zone       = var.az_number

  tags = {
    Name = "terra-priv-sub1"
  }
}
  #  Route table for private subnet 
resource "aws_route_table" "terra-priv-rt" {
  vpc_id = aws_vpc.terra-vpc.id

  tags = {
    Name = "terra-priv-rt"
  }
}
  #  Route table for public subnet 
resource "aws_route_table" "terra-pub-rt" {
  vpc_id     = aws_vpc.terra-vpc.id

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.terra-igw.id
    }

  tags = {
    Name = "terra-pub-rt"

  }
}

  # public route table association
resource "aws_route_table_association" "terra-pub-rt" {
  subnet_id      = aws_subnet.terra-pub-sub1.id
  route_table_id = aws_route_table.terra-pub-rt.id
}
  # private route association
resource "aws_route_table_association" "terra-priv-rt" {
  subnet_id      = aws_subnet.terra-priv-sub1.id
  route_table_id = aws_route_table.terra-priv-rt.id
}

  # Web security group
resource "aws_security_group" "terra-web-sg" {
  name        = "terra-web-sg"
  description = "allow web and ssh traffic"
  vpc_id      = aws_vpc.terra-vpc.id

  ingress {
      description = "HTTP traffic"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks  = ["0.0.0.0/0"]
    }
  ingress {
      description = "shh traffic"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks  = ["76.100.213.107/32"]
    }

  egress {
      from_port  = 0
      to_port    = 0
      protocol   = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

  tags = {
    Name = "terra-web-sg"

  }
}
  # creating ami data source
data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name  = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

  # region variable
variable "aws_region" {
  description = "regions value"
  type        = string
#   default     = "us-east-1"
}
variable "az_number" {
  description = "az value"
  type        = string
#   default     = "us-east-1"
}

  # cvp cidr block variable
variable "vpc_cidr_block" {
  description = "vpc_network id"
  type        = string
  default     = "10.0.0.0/16"
}
  # public subnet cidr block variable
variable "pub_sub1_cidr_block" {
  description = "vpc_network id"
  type        = string
  default     = "10.0.0.0/24"
}
  # private subnet cidr block variable
variable "priv_sub1_cidr_block" {
  description = "vpc_network id"
  type        = string
  default     = "10.0.1.0/24"
}
  # instance type variable
variable "aws_instance_type" {
  description = "instance type"
  type        = string
  default     = "t2.micro"
}
  # instance key pair variable
variable "instance_key_pair" {
  description = "instance type"
  type        = string
  default     = "Ansible-Ohio-KP" 
}

  # creating EC2  instance in the public subnet
resource "aws_instance" "pub-instance-sub1" {
  ami                         = data.aws_ami.amazon-linux-2.id
  availability_zone           = var.az_number
  instance_type               = var.aws_instance_type
  key_name                    = var.instance_key_pair
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.terra-pub-sub1.id
  security_groups        = [aws_security_group.terra-web-sg.id]

  tags = {
    Name = "publicinstance"
  }
}
  # creating an EC2 instance in the private subnet
resource "aws_instance" "priv-instance-sub1" {
  ami                 = data.aws_ami.amazon-linux-2.id
  availability_zone   = var.az_number
  instance_type       = var.aws_instance_type
  key_name            = var.instance_key_pair
  subnet_id           = aws_subnet.terra-priv-sub1.id
  security_groups = [aws_security_group.terra-web-sg.id]

  tags = {
    Name = "privateinstance"
  }

}   
