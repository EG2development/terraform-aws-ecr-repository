# Resource names are "main" rather than the more common "this" so that callers
# migrating from an in-repository copy of this module keep their existing
# resource addresses. Renaming them is a breaking change and must ship with
# `moved` blocks in a major release.

locals {
  default_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.tagged_image_retention_count} tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = var.tagged_image_prefixes
          countType     = "imageCountMoreThan"
          countNumber   = var.tagged_image_retention_count
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Remove untagged images older than ${var.untagged_image_expiry_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.untagged_image_expiry_days
        }
        action = {
          type = "expire"
        }
      }
    ]
  })

  lifecycle_policy = var.lifecycle_policy_json != null ? var.lifecycle_policy_json : local.default_lifecycle_policy
}

resource "aws_ecr_repository" "main" {
  name                 = var.name
  image_tag_mutability = var.image_tag_mutability
  force_delete         = var.force_delete

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = var.encryption_type
    kms_key         = var.kms_key_arn
  }

  tags = merge({ Name = var.name }, var.tags)

  lifecycle {
    precondition {
      condition     = var.kms_key_arn == null || var.encryption_type == "KMS"
      error_message = "kms_key_arn can only be set when encryption_type is \"KMS\"."
    }

    # A policy passed without the flag would otherwise be dropped silently.
    precondition {
      condition     = var.create_repository_policy || var.repository_policy_json == null
      error_message = "repository_policy_json is set but create_repository_policy is false. Set create_repository_policy = true to attach the policy."
    }
  }
}

# Always present: a repository without a lifecycle policy keeps every image
# forever. Callers that want different rules pass lifecycle_policy_json.
resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name
  policy     = local.lifecycle_policy
}

resource "aws_ecr_repository_policy" "main" {
  count = var.create_repository_policy ? 1 : 0

  repository = aws_ecr_repository.main.name
  policy     = var.repository_policy_json

  lifecycle {
    precondition {
      condition     = var.repository_policy_json != null
      error_message = "create_repository_policy is true but repository_policy_json is not set."
    }
  }
}
