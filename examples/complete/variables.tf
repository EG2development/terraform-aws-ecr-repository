variable "region" {
  description = "AWS Region to create the repository in."
  type        = string
}

variable "name" {
  description = "Repository name."
  type        = string
  default     = "example/service"
}

variable "kms_key_arn" {
  description = "ARN of an existing customer managed KMS key in the same Region. The key policy must allow ECR to use it."
  type        = string
}

variable "pull_principal_arns" {
  description = "IAM principal ARNs (usually account roots or roles in other accounts) allowed to pull images. Empty attaches no repository policy."
  type        = list(string)
  default     = []
}
