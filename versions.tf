terraform {
  # Minimum versions only: a reusable module states what it needs and leaves
  # upper bounds to the root module that calls it. CI tests 1.7.5 (the newest
  # patch of the oldest allowed minor) and the latest release; 1.7 is also the
  # first version whose test framework supports mock providers.
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
