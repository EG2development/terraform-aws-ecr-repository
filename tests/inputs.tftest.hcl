# Each optional input changes exactly what it says it changes.

mock_provider "aws" {}

variables {
  name = "team/service"
}

run "mutable_tags_and_force_delete_can_be_chosen" {
  command = plan

  variables {
    image_tag_mutability = "MUTABLE"
    force_delete         = true
    scan_on_push         = false
  }

  assert {
    condition     = aws_ecr_repository.main.image_tag_mutability == "MUTABLE"
    error_message = "image_tag_mutability must be passed through."
  }

  assert {
    condition     = aws_ecr_repository.main.force_delete == true
    error_message = "force_delete must be passed through."
  }

  assert {
    condition     = aws_ecr_repository.main.image_scanning_configuration[0].scan_on_push == false
    error_message = "scan_on_push must be passed through."
  }
}

run "customer_managed_key_is_used" {
  command = plan

  variables {
    kms_key_arn = "arn:aws:kms:eu-west-2:111122223333:key/00000000-0000-0000-0000-000000000000"
  }

  assert {
    condition     = aws_ecr_repository.main.encryption_configuration[0].kms_key == "arn:aws:kms:eu-west-2:111122223333:key/00000000-0000-0000-0000-000000000000"
    error_message = "kms_key_arn must be passed to the encryption configuration."
  }
}

run "aes256_encryption_can_be_chosen" {
  command = plan

  variables {
    encryption_type = "AES256"
  }

  assert {
    condition     = aws_ecr_repository.main.encryption_configuration[0].encryption_type == "AES256"
    error_message = "encryption_type must be passed through."
  }
}

run "default_lifecycle_policy_follows_its_inputs" {
  command = plan

  variables {
    tagged_image_prefixes        = ["release-", "v"]
    tagged_image_retention_count = 25
    untagged_image_expiry_days   = 3
  }

  assert {
    condition     = jsondecode(aws_ecr_lifecycle_policy.main.policy).rules[0].selection.tagPrefixList == ["release-", "v"]
    error_message = "The tagged rule must use tagged_image_prefixes."
  }

  assert {
    condition     = jsondecode(aws_ecr_lifecycle_policy.main.policy).rules[0].selection.countNumber == 25
    error_message = "The tagged rule must keep tagged_image_retention_count images."
  }

  assert {
    condition     = jsondecode(aws_ecr_lifecycle_policy.main.policy).rules[1].selection.countNumber == 3
    error_message = "The untagged rule must expire after untagged_image_expiry_days."
  }
}

run "caller_lifecycle_policy_replaces_the_default" {
  command = plan

  variables {
    lifecycle_policy_json = "{\"rules\":[{\"rulePriority\":1,\"selection\":{\"tagStatus\":\"any\",\"countType\":\"imageCountMoreThan\",\"countNumber\":100},\"action\":{\"type\":\"expire\"}}]}"
  }

  assert {
    condition     = aws_ecr_lifecycle_policy.main.policy == "{\"rules\":[{\"rulePriority\":1,\"selection\":{\"tagStatus\":\"any\",\"countType\":\"imageCountMoreThan\",\"countNumber\":100},\"action\":{\"type\":\"expire\"}}]}"
    error_message = "lifecycle_policy_json must be used verbatim."
  }
}

run "repository_policy_is_attached_when_requested" {
  command = plan

  variables {
    create_repository_policy = true
    repository_policy_json   = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"Pull\",\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::111122223333:root\"},\"Action\":[\"ecr:BatchGetImage\",\"ecr:GetDownloadUrlForLayer\"]}]}"
  }

  assert {
    condition     = length(aws_ecr_repository_policy.main) == 1
    error_message = "A repository policy must be created when create_repository_policy is true."
  }

  assert {
    condition     = aws_ecr_repository_policy.main[0].repository == "team/service"
    error_message = "The repository policy must be attached to the module's repository."
  }
}

run "caller_tags_are_merged_and_may_override_name" {
  command = plan

  variables {
    tags = {
      Name        = "custom"
      Environment = "test"
    }
  }

  assert {
    condition     = aws_ecr_repository.main.tags == tomap({ Name = "custom", Environment = "test" })
    error_message = "var.tags must be merged over the default Name tag."
  }
}

# The flag, not the JSON, decides whether the policy exists, so a policy that
# names a role created in the same apply (unknown at plan time) still plans.
run "repository_policy_may_be_unknown_at_plan_time" {
  command = plan

  module {
    source = "./tests/fixtures/policy-from-new-role"
  }

  assert {
    condition     = length(module.ecr_repository.repository_name) > 0
    error_message = "The module must plan when repository_policy_json is unknown until apply."
  }
}
