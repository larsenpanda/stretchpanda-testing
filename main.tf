terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

provider "aws" {
  alias = "useast1"
  profile = "default"
  region  = "us-east-1"
}

provider "aws" {
  alias = "useast2"
  profile = "default"
  region  = "us-east-2"
}

provider "aws" {
  alias = "uswest2"
  profile = "default"
  region  = "us-west-2"
}

resource "aws_vpc" "custom-vpc-2" {
  provider = aws.useast1
  cidr_block = "10.1.1.0/24"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "larsen-stretch-test"
  }
}

resource "aws_vpc" "custom-vpc-3" {
  provider = aws.useast2
  cidr_block = "10.1.1.0/24"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "larsen-stretch-test"
  }
}

resource "aws_vpc" "custom-vpc-4" {
  provider = aws.uswest2
  cidr_block = "10.1.1.0/24"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "larsen-stretch-test"
  }
}

resource "aws_subnet" "custom-subnet-2" {
  provider = aws.useast1
  cidr_block = "10.1.1.0/24"
  vpc_id = aws_vpc.custom-vpc-2.id
  availability_zone = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "larsen-stretch-test"
  }
}

resource "aws_subnet" "custom-subnet-3" {
  provider = aws.useast2
  cidr_block = "10.1.1.0/24"
  vpc_id = aws_vpc.custom-vpc-3.id
  map_public_ip_on_launch = true
  tags = {
    Name = "larsen-stretch-test"
  }
}

resource "aws_subnet" "custom-subnet-4" {
  provider = aws.uswest2
  cidr_block = "10.1.1.0/24"
  vpc_id = aws_vpc.custom-vpc-4.id
  map_public_ip_on_launch = true
  tags = {
    Name = "larsen-stretch-test"
  }
}

resource "aws_internet_gateway" "custom-igw-2" {
  provider = aws.useast1
  vpc_id = aws_vpc.custom-vpc-2.id
  tags = {
    Name = "larsen-stretch-test"
  }
}

resource "aws_internet_gateway" "custom-igw-3" {
  provider = aws.useast2
  vpc_id = aws_vpc.custom-vpc-3.id
  tags = {
    Name = "larsen-stretch-test"
  }
}

resource "aws_internet_gateway" "custom-igw-4" {
  provider = aws.uswest2
  vpc_id = aws_vpc.custom-vpc-4.id
  tags = {
    Name = "larsen-stretch-test"
  }
}

resource "aws_route_table" "custom-rt2" {
  provider = aws.useast1
  vpc_id = aws_vpc.custom-vpc-2.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.custom-igw-2.id
  }
  tags = {
    Name = "larsen-stretch-test"
  }
}

resource "aws_route_table" "custom-rt3" {
  provider = aws.useast2
  vpc_id = aws_vpc.custom-vpc-3.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.custom-igw-3.id
  }
  tags = {
    Name = "larsen-stretch-test"
  }
}

resource "aws_route_table" "custom-rt4" {
  provider = aws.uswest2
  vpc_id = aws_vpc.custom-vpc-4.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.custom-igw-4.id
  }
  tags = {
    Name = "larsen-stretch-test"
  }
}

resource "aws_route_table_association" "custom-rt-association-2" {
  provider = aws.useast1
  route_table_id = aws_route_table.custom-rt2.id
  subnet_id = aws_subnet.custom-subnet-2.id
}

resource "aws_route_table_association" "custom-rt-association-3" {
  provider = aws.useast2
  route_table_id = aws_route_table.custom-rt3.id
  subnet_id = aws_subnet.custom-subnet-3.id
}

resource "aws_route_table_association" "custom-rt-association-4" {
  provider = aws.uswest2
  route_table_id = aws_route_table.custom-rt4.id
  subnet_id = aws_subnet.custom-subnet-4.id
}

variable "ingress-rules" {
  default = {
    "rp-ingress" = {
      description = "For Redpanda Kafka"
      from_port   = 9092
      to_port     = 9092
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    "ssh-ingress" = {
      description = "For SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    "rpadmin-ingress" = {
      description = "For Redpanda Admin"
      from_port   = 9644
      to_port     = 9644
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    "rprpc-ingress" = {
      description = "For Redpanda RPC"
      from_port   = 33145
      to_port     = 33145
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  type = map(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
}

variable "egress-rules" {
  default = {
    "all-egress" = {
      description = "All"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  type = map(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
}

resource "aws_security_group" "custom-sg2" {
  provider = aws.useast1
  name = "allow_rp_and_ssh"
  description = "Allow Redpanda and SSH traffic"
  vpc_id = aws_vpc.custom-vpc-2.id
  tags = {
    Name = "larsen-stretch-test"
  }
  dynamic "ingress" {
    for_each = var.ingress-rules
    content {
      description      = lookup(ingress.value, "description", null)
      from_port        = lookup(ingress.value, "from_port", null)
      to_port          = lookup(ingress.value, "to_port", null)
      protocol         = lookup(ingress.value, "protocol", null)
      cidr_blocks      = lookup(ingress.value, "cidr_blocks", null)
    }
  }

  dynamic "egress" {
    for_each = var.egress-rules
    content {
      description      = lookup(egress.value, "description", null)
      from_port        = lookup(egress.value, "from_port", null)
      to_port          = lookup(egress.value, "to_port", null)
      protocol         = lookup(egress.value, "protocol", null)
      cidr_blocks      = lookup(egress.value, "cidr_blocks", null)
    }
  }
}

resource "aws_security_group" "custom-sg3" {
  provider = aws.useast2
  name = "allow_rp_and_ssh"
  description = "Allow Redpanda and SSH traffic"
  vpc_id = aws_vpc.custom-vpc-3.id
  tags = {
    Name = "larsen-stretch-test"
  }
  dynamic "ingress" {
    for_each = var.ingress-rules
    content {
      description      = lookup(ingress.value, "description", null)
      from_port        = lookup(ingress.value, "from_port", null)
      to_port          = lookup(ingress.value, "to_port", null)
      protocol         = lookup(ingress.value, "protocol", null)
      cidr_blocks      = lookup(ingress.value, "cidr_blocks", null)
    }
  }

  dynamic "egress" {
    for_each = var.egress-rules
    content {
      description      = lookup(egress.value, "description", null)
      from_port        = lookup(egress.value, "from_port", null)
      to_port          = lookup(egress.value, "to_port", null)
      protocol         = lookup(egress.value, "protocol", null)
      cidr_blocks      = lookup(egress.value, "cidr_blocks", null)
    }
  }
}

resource "aws_security_group" "custom-sg4" {
  provider = aws.uswest2
  name = "allow_rp_and_ssh"
  description = "Allow Redpanda and SSH traffic"
  vpc_id = aws_vpc.custom-vpc-4.id
  tags = {
    Name = "larsen-stretch-test"
  }
  dynamic "ingress" {
    for_each = var.ingress-rules
    content {
      description      = lookup(ingress.value, "description", null)
      from_port        = lookup(ingress.value, "from_port", null)
      to_port          = lookup(ingress.value, "to_port", null)
      protocol         = lookup(ingress.value, "protocol", null)
      cidr_blocks      = lookup(ingress.value, "cidr_blocks", null)
    }
  }

  dynamic "egress" {
    for_each = var.egress-rules
    content {
      description      = lookup(egress.value, "description", null)
      from_port        = lookup(egress.value, "from_port", null)
      to_port          = lookup(egress.value, "to_port", null)
      protocol         = lookup(egress.value, "protocol", null)
      cidr_blocks      = lookup(egress.value, "cidr_blocks", null)
    }
  }
}

resource "aws_instance" "custom-ec2-2" {
  provider = aws.useast1
  ami = "ami-06eecef118bbf9259"
  instance_type = "i3en.large"
  key_name = "larsenrp"
  subnet_id = aws_subnet.custom-subnet-2.id
  associate_public_ip_address = true
  user_data = ""
  root_block_device {
    volume_size = 100
  }
  tags = {
    Name = "larsen-stretch-test"
  }
  vpc_security_group_ids = [aws_security_group.custom-sg2.id]
}

resource "aws_instance" "custom-ec2-3" {
  provider = aws.useast2
  ami = "ami-0fe23c115c3ba9bac"
  instance_type = "i3en.large"
  key_name = "larsenrp"
  subnet_id = aws_subnet.custom-subnet-3.id
  associate_public_ip_address = true
  user_data = ""
  root_block_device {
    volume_size = 100
  }
  tags = {
    Name = "larsen-stretch-test"
  }
  vpc_security_group_ids = [aws_security_group.custom-sg3.id]
}

resource "aws_instance" "custom-ec2-4" {
  provider = aws.uswest2
  ami = "ami-00af37d1144686454"
  instance_type = "i3en.large"
  key_name = "larsenrp"
  subnet_id = aws_subnet.custom-subnet-4.id
  associate_public_ip_address = true
  user_data = ""
  root_block_device {
    volume_size = 100 
  }
  tags = {
    Name = "larsen-stretch-test"
  }
  vpc_security_group_ids = [aws_security_group.custom-sg4.id]
}