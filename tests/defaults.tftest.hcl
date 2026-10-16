# The secure defaults a caller gets by setting only `name`. A change to any of
# these assertions changes infrastructure for existing callers, which is a
# major release (see CHANGELOG.md).

mock_provider "aws" {}

variables {
  name = "team/service"
}

run "repository_has_secure_defaults" {
  command = plan

  assert {
    condition     = aws_ecr_repository.main.name == "team/service"
    error_message = "The repository must be named from var.name."
  }

  assert {
    condition     = aws_ecr_repository.main.image_tag_mutability == "IMMUTABLE"
    error_message = "Tags must be immutable by default."
  }

  assert {
    condition     = aws_ecr_repository.main.force_delete == false
    error_message = "force_delete must be off by default so images survive a mistaken destroy."
  }

  assert {
    condition     = aws_ecr_repository.main.image_scanning_configuration[0].scan_on_push == true
    error_message = "Images must be scanned on push by default."
  }

  assert {
    condition     = aws_ecr_repository.main.encryption_configuration[0].encryption_type == "KMS"
    error_message = "The repository must be encrypted with KMS by default."
  }

  assert {
    condition     = aws_ecr_repository.main.tags == tomap({ Name = "team/service" })
    error_message = "Only a Name tag is added when var.tags is empty."
  }

  assert {
    condition     = length(aws_ecr_repository_policy.main) == 0
    error_message = "No repository policy may be attached unless the caller supplies one."
  }

  assert {
    condition     = output.repository_name == "team/service"
    error_message = "The repository_name output must report the repository's name."
  }
}

run "default_lifecycle_policy_is_stable" {
  command = plan

  # Byte-for-byte: callers migrating from an in-repository copy of this module
  # rely on the default policy being identical, so their plan shows no change.
  assert {
    condition     = aws_ecr_lifecycle_policy.main.policy == "{\"rules\":[{\"action\":{\"type\":\"expire\"},\"description\":\"Keep last 10 tagged images\",\"rulePriority\":1,\"selection\":{\"countNumber\":10,\"countType\":\"imageCountMoreThan\",\"tagPrefixList\":[\"v\"],\"tagStatus\":\"tagged\"}},{\"action\":{\"type\":\"expire\"},\"description\":\"Remove untagged images older than 7 days\",\"rulePriority\":2,\"selection\":{\"countNumber\":7,\"countType\":\"sinceImagePushed\",\"countUnit\":\"days\",\"tagStatus\":\"untagged\"}}]}"
    error_message = "The default lifecycle policy changed. That changes every caller's infrastructure and needs a major release."
  }

  assert {
    condition     = aws_ecr_lifecycle_policy.main.repository == "team/service"
    error_message = "The lifecycle policy must be attached to the module's repository."
  }
}
