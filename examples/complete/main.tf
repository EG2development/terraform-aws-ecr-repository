# Every extension point in use: a customer managed KMS key, a caller-supplied
# lifecycle policy, and a repository policy that lets other AWS accounts pull.

provider "aws" {
  region = var.region
}

# Pull-only access for principals in other accounts. Push stays with IAM
# principals in the owning account.
data "aws_iam_policy_document" "cross_account_pull" {
  count = length(var.pull_principal_arns) > 0 ? 1 : 0

  statement {
    sid    = "CrossAccountPull"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = var.pull_principal_arns
    }

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]
  }
}

module "ecr_repository" {
  # A real caller uses a pinned Git source instead, for example
  # "git::https://github.com/EG2development/terraform-aws-ecr-repository.git?ref=v1.0.0"
  source = "../.."

  name                 = var.name
  image_tag_mutability = "IMMUTABLE"
  force_delete         = false
  scan_on_push         = true

  encryption_type = "KMS"
  kms_key_arn     = var.kms_key_arn

  # Keep the 30 most recent release images; expire untagged images after a day.
  lifecycle_policy_json = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep the 30 most recent release images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["release-"]
          countType     = "imageCountMoreThan"
          countNumber   = 30
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Expire untagged images after one day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = { type = "expire" }
      }
    ]
  })

  create_repository_policy = length(var.pull_principal_arns) > 0
  repository_policy_json   = length(var.pull_principal_arns) > 0 ? data.aws_iam_policy_document.cross_account_pull[0].json : null

  tags = {
    Environment = "example"
    Owner       = "platform"
  }
}
