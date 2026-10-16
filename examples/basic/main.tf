# The smallest useful call: a private repository with the module's secure
# defaults (immutable tags, scan on push, KMS encryption, lifecycle policy).

provider "aws" {
  region = var.region
}

module "ecr_repository" {
  # A real caller uses a pinned Git source instead, for example
  # "git::https://github.com/EG2development/terraform-aws-ecr-repository.git?ref=v1.0.0"
  source = "../.."

  name = var.name

  tags = {
    Environment = "example"
  }
}
