# Test fixture: a caller whose repository policy names a role created in the
# same apply, so the policy JSON is unknown at plan time.

resource "aws_iam_role" "puller" {
  name = "example-puller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

data "aws_iam_policy_document" "pull" {
  statement {
    sid     = "Pull"
    actions = ["ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.puller.arn]
    }
  }
}

module "ecr_repository" {
  source = "../../.."

  name                     = "team/service"
  create_repository_policy = true
  repository_policy_json   = data.aws_iam_policy_document.pull.json
}
