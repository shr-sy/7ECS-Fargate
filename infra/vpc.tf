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
# Subnet CIDRs
#########################################

locals {
  # PUBLIC SUBNETS (must be in different AZs)
  public_subnets = {
    a = "10.0.1.0/24"
    b = "10.0.2.0/24"
  }

  # PRIVATE SUBNETS (must be in different AZs)
  private_subnets = {
    a = "10.0.11.0/24"
    b = "10.0.12.0/24"
  }

  azs = {
    a = "us-east-1a"
    b = "us-east-1b"
  }
}

#########################################
# Public Subnets
#########################################

resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = local.azs[each.key]

  map_public_ip_on_launch = true

  tags = {
    Name = "myproject-public-${each.key}"
  }
}

#########################################
# Private Subnets
#########################################

resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = local.azs[each.key]

  map_public_ip_on_launch = false

  tags = {
    Name = "myproject-private-${each.key}"
  }
}

#########################################
# Public Route Table + Assoc
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

  route_table_id = aws_route_table.public.id
  subnet_id      = each.value.id
}

#########################################
# Security Group – ALB
#########################################

resource "aws_security_group" "ecs_sg" {
  name        = "${var.project_name}-ecs-sg"
  vpc_id      = aws_vpc.this.id
  description = "Allow traffic from ALB"

  ingress {
    description    = "ALB to ECS traffic"
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
  tags = {
    Name = "myproject-alb-sg"
  }
}

#########################################
# Security Group – ECS Tasks
#########################################

resource "aws_security_group" "ecs_sg" {
  name        = "myproject-ecs-sg"
  vpc_id      = aws_vpc.this.id
  description = "Allow app traffic from ALB"

  ingress {
    description    = "Allow ALB → ECS"
    from_port       = 80   # ECS container port
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
    Name = "myproject-ecs-sg"
  }
}

#########################################
# Outputs
#########################################

output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = [
    for s in aws_subnet.public : s.id
  ]
}

output "private_subnet_ids" {
  value = [
    for s in aws_subnet.private : s.id
  ]
}

output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}

output "ecs_sg_id" {
  value = aws_security_group.ecs_sg.id
}
