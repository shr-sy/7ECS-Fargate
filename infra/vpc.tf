resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  tags = { Name = "${var.project_name}-vpc" }
}

resource "aws_internet_gateway" "igw" { vpc_id = aws_vpc.this.id }

resource "aws_subnet" "public" {
  for_each = toset(var.public_subnets)
  vpc_id = aws_vpc.this.id
  cidr_block = each.key
  map_public_ip_on_launch = true
  tags = { Name = "${var.project_name}-pub-${replace(each.key, ".", "-")}" }
}

resource "aws_subnet" "private" {
  for_each = toset(var.private_subnets)
  vpc_id = aws_vpc.this.id
  cidr_block = each.key
  map_public_ip_on_launch = false
  tags = { Name = "${var.project_name}-priv-${replace(each.key, ".", "-")}" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route { cidr_block = "0.0.0.0/0" , gateway_id = aws_internet_gateway.igw.id }
  tags = { Name = "${var.project_name}-public-rt" }
}

resource "aws_route_table_association" "public_assoc" {
  for_each = aws_subnet.public
  subnet_id = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "alb_sg" {
  name = "${var.project_name}-alb-sg"
  vpc_id = aws_vpc.this.id
  description = "Allow HTTP from internet"
  ingress {
    from_port = 80; to_port = 80; protocol = "tcp"; cidr_blocks = ["0.0.0.0/0"]
  }
  egress { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }
}

resource "aws_security_group" "ecs_sg" {
  name = "${var.project_name}-ecs-sg"
  vpc_id = aws_vpc.this.id
  description = "Allow traffic from ALB only"
  ingress {
    from_port = 3000; to_port = 3000; protocol = "tcp"; security_groups = [aws_security_group.alb_sg.id]
  }
  egress { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }
}
