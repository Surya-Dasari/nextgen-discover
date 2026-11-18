
# --------------------------------------------------
# NextGen Discover ECR Repositories
# --------------------------------------------------

resource "aws_ecr_repository" "this" {
  for_each = var.repository_names

  name                 = "${var.project_name}/${each.value}"
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = var.kms_key_arn == null ? "AES256" : "KMS"

    kms_key = var.kms_key_arn
  }

  tags = merge(var.tags, {
    Name      = "${var.project_name}-${each.value}"
    Component = "ECR"
  })
}
