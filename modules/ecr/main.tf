resource "aws_ecr_repository" "repo" {
  name                 = var.name
  image_tag_mutability = var.mutability

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Terraform   = "true"
    Environment = "global"
  }
}