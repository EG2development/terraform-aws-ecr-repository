# Invalid input is rejected at plan time with a clear message, before any
# API call is made.

mock_provider "aws" {}

variables {
  name = "team/service"
}

run "rejects_uppercase_name" {
  command = plan

  variables {
    name = "Team/Service"
  }

  expect_failures = [var.name]
}

run "rejects_name_ending_in_a_separator" {
  command = plan

  variables {
    name = "team/"
  }

  expect_failures = [var.name]
}

run "rejects_one_character_name" {
  command = plan

  variables {
    name = "a"
  }

  expect_failures = [var.name]
}

run "rejects_unknown_tag_mutability" {
  command = plan

  variables {
    image_tag_mutability = "SOMETIMES"
  }

  expect_failures = [var.image_tag_mutability]
}

run "rejects_unknown_encryption_type" {
  command = plan

  variables {
    encryption_type = "NONE"
  }

  expect_failures = [var.encryption_type]
}

run "rejects_kms_key_without_kms_encryption" {
  command = plan

  variables {
    encryption_type = "AES256"
    kms_key_arn     = "arn:aws:kms:eu-west-2:111122223333:key/00000000-0000-0000-0000-000000000000"
  }

  expect_failures = [aws_ecr_repository.main]
}

run "rejects_zero_retention_count" {
  command = plan

  variables {
    tagged_image_retention_count = 0
  }

  expect_failures = [var.tagged_image_retention_count]
}

run "rejects_fractional_expiry" {
  command = plan

  variables {
    untagged_image_expiry_days = 1.5
  }

  expect_failures = [var.untagged_image_expiry_days]
}

run "rejects_empty_prefix_list" {
  command = plan

  variables {
    tagged_image_prefixes = []
  }

  expect_failures = [var.tagged_image_prefixes]
}

run "rejects_invalid_lifecycle_json" {
  command = plan

  variables {
    lifecycle_policy_json = "{not json"
  }

  expect_failures = [var.lifecycle_policy_json]
}

run "rejects_policy_flag_without_policy" {
  command = plan

  variables {
    create_repository_policy = true
  }

  expect_failures = [aws_ecr_repository_policy.main]
}

run "rejects_policy_without_policy_flag" {
  command = plan

  variables {
    repository_policy_json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
  }

  expect_failures = [aws_ecr_repository.main]
}

run "rejects_invalid_repository_policy_json" {
  command = plan

  variables {
    repository_policy_json = "{not json"
  }

  expect_failures = [var.repository_policy_json]
}

# Names the ECR API accepts must not be rejected by the module.

run "accepts_namespaced_name_from_the_aws_documentation" {
  command = plan

  variables {
    name = "project-a/nginx-web-app"
  }

  assert {
    condition     = aws_ecr_repository.main.name == "project-a/nginx-web-app"
    error_message = "A namespaced name must be accepted."
  }
}

run "accepts_double_underscore_and_dot_separators" {
  command = plan

  variables {
    name = "team__one/service.api"
  }

  assert {
    condition     = aws_ecr_repository.main.name == "team__one/service.api"
    error_message = "Double underscores and dots are valid separators."
  }
}

run "accepts_repeated_hyphens" {
  command = plan

  variables {
    name = "service--canary"
  }

  assert {
    condition     = aws_ecr_repository.main.name == "service--canary"
    error_message = "One or more hyphens is a valid separator."
  }
}
