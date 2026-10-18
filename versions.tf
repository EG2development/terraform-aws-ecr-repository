terraform {
  # Minimum versions only: a reusable module states what it needs and leaves
  # upper bounds to the root module that calls it. 1.16 is the floor shared by
  # every module in this family, so a caller needs one Terraform minimum for
  # all of them. CI tests 1.16.6 (the newest patch of that minor) and the
  # latest release.
  required_version = ">= 1.16.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
