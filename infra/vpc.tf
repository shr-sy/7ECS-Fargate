#########################################
# VPC
#########################################
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

#########################################
# Internet Gateway
#########################################
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

#########################################
# Availability Zones (auto-discover)
#########################################
data "aws_availability_zones" "available" {}

#########################################
# Public Subnets
#########################################
resource "aws_subnet" "public" {
  for_each = toset(var.public_subnets)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  availability_zone       = data.aws_availability_zones.available.names[index(var.public_subnets, each.value)]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-${index(var.public_subnets, each.value)}"
  }
}

#########################################
# Private Subnets
#########################################
resource "aws_subnet" "private" {
  for_each = toset(var.private_subnets)

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = data.aws_availability_zones.available.names[index(var.private_subnets, each.value)]

  tags = {
    Name = "${var.project_name}-private-${index(var.private_subnets, each.value)}"
  }
}

#########################################
# Public Route Table + Default Route
#########################################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  for_each = aws_subnet.public

  route_table_id = aws_route_table.public.id
  subnet_id      = each.value.id
}

#########################################
# Security Group – ALB
#########################################
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  vpc_id      = aws_vpc.this.id
  description = "Security group for ALB"

  ingress {
    description = "Allow inbound HTTP traffic"
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

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

#########################################
# Security Group – ECS Tasks
#########################################
resource "aws_security_group" "ecs_sg" {
  name        = "${var.project_name}-ecs-sg"
  vpc_id      = aws_vpc.this.id
  description = "Allow ALB to ECS traffic"

  ingress {
    description    = "ALB to ECS"
    from_port       = 80   # ECS default; dynamic per-service later
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ecs-sg"
  }
}

#########################################
# Outputs
#########################################
output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = [for subnet in aws_subnet.public : subnet.id]
}

output "private_subnet_ids" {
  value = [for subnet in aws_subnet.private : subnet.id]
}

output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}

output "ecs_sg_id" {
  value = aws_security_group.ecs_sg.id
}
