# The examples in the README are real configurations. These runs plan each one
# against the mocked provider so an example that stops working fails CI.

mock_provider "aws" {}

run "basic_example_plans" {
  command = plan

  module {
    source = "./examples/basic"
  }

  variables {
    region = "eu-west-2"
  }

  assert {
    condition     = module.ecr_repository.repository_name == "example/app"
    error_message = "The basic example must create the example/app repository."
  }
}

run "complete_example_plans_with_cross_account_pull" {
  command = plan

  module {
    source = "./examples/complete"
  }

  variables {
    region              = "eu-west-2"
    kms_key_arn         = "arn:aws:kms:eu-west-2:111122223333:key/00000000-0000-0000-0000-000000000000"
    pull_principal_arns = ["arn:aws:iam::444455556666:root"]
  }

  # The policy document is rendered locally by the real provider; the mock
  # would return a random string, so the test supplies realistic JSON.
  override_data {
    target = data.aws_iam_policy_document.cross_account_pull
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"CrossAccountPull\",\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::444455556666:root\"},\"Action\":[\"ecr:BatchCheckLayerAvailability\",\"ecr:BatchGetImage\",\"ecr:GetDownloadUrlForLayer\"]}]}"
    }
  }

  assert {
    condition     = module.ecr_repository.repository_name == "example/service"
    error_message = "The complete example must create the example/service repository."
  }
}
