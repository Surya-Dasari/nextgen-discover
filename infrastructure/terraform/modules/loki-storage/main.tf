data "aws_caller_identity" "current" {}

locals {
  bucket_name = "${var.project_name}-loki-${data.aws_caller_identity.current.account_id}-${var.aws_region}"

  common_tags = merge(var.tags, {
    Project   = var.project_name
    Component = "observability"
    ManagedBy = "Terraform"
  })
}

# --------------------------------------------------
# Loki S3 Storage Bucket
# --------------------------------------------------

resource "aws_s3_bucket" "loki" {
  bucket = local.bucket_name

  tags = merge(local.common_tags, {
    Name = local.bucket_name
  })
}

resource "aws_s3_bucket_public_access_block" "loki" {
  bucket = aws_s3_bucket.loki.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "loki" {
  bucket = aws_s3_bucket.loki.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "loki" {
  bucket = aws_s3_bucket.loki.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }

    bucket_key_enabled = false
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "loki" {
  bucket = aws_s3_bucket.loki.id

  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# --------------------------------------------------
# Loki EKS Pod Identity IAM Role
# --------------------------------------------------

resource "aws_iam_role" "loki" {
  name = "${var.project_name}-loki-storage-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "pods.eks.amazonaws.com"
      }

      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]

      Condition = {
        StringEquals = {
          "aws:RequestTag/kubernetes-namespace"       = var.namespace
          "aws:RequestTag/kubernetes-service-account" = var.service_account
          "aws:RequestTag/eks-cluster-arn"            = var.cluster_arn
        }
      }
    }]
  })

  tags = local.common_tags
}

# --------------------------------------------------
# Loki S3 Access Policy
# --------------------------------------------------

resource "aws_iam_role_policy" "loki_s3" {
  name = "${var.project_name}-loki-s3-access"
  role = aws_iam_role.loki.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ListLokiBucket"
        Effect = "Allow"

        Action = [
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads"
        ]

        Resource = aws_s3_bucket.loki.arn
      },
      {
        Sid    = "ManageLokiObjects"
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts"
        ]

        Resource = "${aws_s3_bucket.loki.arn}/*"
      }
    ]
  })
}

# --------------------------------------------------
# EKS Pod Identity Association
# --------------------------------------------------

resource "aws_eks_pod_identity_association" "loki" {
  cluster_name    = var.cluster_name
  namespace       = var.namespace
  service_account = var.service_account
  role_arn        = aws_iam_role.loki.arn

  depends_on = [
    aws_iam_role_policy.loki_s3,
    aws_s3_bucket_public_access_block.loki,
    aws_s3_bucket_server_side_encryption_configuration.loki
  ]
}
