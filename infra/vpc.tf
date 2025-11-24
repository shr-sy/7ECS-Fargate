#########################################
# VPC
#########################################

resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "myproject-vpc"
  }
}

#########################################
# Internet Gateway
#########################################

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "myproject-igw"
  }
}

#########################################
# Public Subnets
#########################################

locals {
  public_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  private_subnets = [
    "10.0.11.0/24",
    "10.0.12.0/24"
  ]
}

resource "aws_subnet" "public" {
  for_each = { for idx, cidr in local.public_subnets : idx => cidr }

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  map_public_ip_on_launch = true

  tags = {
    Name = "myproject-public-${each.key}"
  }
}

#########################################
# Private Subnets
#########################################

resource "aws_subnet" "private" {
  for_each = { for idx, cidr in local.private_subnets : idx => cidr }

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  map_public_ip_on_launch = false

  tags = {
    Name = "myproject-private-${each.key}"
  }
}

#########################################
# Public Route Table + Routes
#########################################

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "myproject-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

#########################################
# Security Group – ALB
#########################################

resource "aws_security_group" "alb_sg" {
  name        = "myproject-alb-sg"
  vpc_id      = aws_vpc.this.id
  description = "Allow HTTP from internet"

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#########################################
# Security Group – ECS
#########################################

resource "aws_security_group" "ecs_sg" {
  name        = "myproject-ecs-sg"
  vpc_id      = aws_vpc.this.id
  description = "Allow App traffic from ALB"

  ingress {
    description    = "Allow traffic from ALB"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#########################################
# Outputs (still inside same file)
#########################################

output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  value = [for s in aws_subnet.private : s.id]
}

output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}

output "ecs_sg_id" {
  value = aws_security_group.ecs_sg.id
}
