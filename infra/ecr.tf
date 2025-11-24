resource "aws_ecr_repository" "services" {
  for_each = toset(var.services)
  name = "${var.project_name}-${each.key}"
  image_tag_mutability = "MUTABLE"
}
