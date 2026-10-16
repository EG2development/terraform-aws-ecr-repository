variable "name" {
  description = "Name of the ECR repository. May contain a namespace, for example \"team/service\". Changing it replaces the repository and deletes its images."
  type        = string
  nullable    = false

  validation {
    # The length limits and pattern of repositoryName in the ECR
    # CreateRepository API reference, anchored.
    condition = (
      length(var.name) >= 2 &&
      length(var.name) <= 256 &&
      can(regex("^[a-z0-9]+(?:(?:\\.|_|__|-+)[a-z0-9]+)*(?:/[a-z0-9]+(?:(?:\\.|_|__|-+)[a-z0-9]+)*)*$", var.name))
    )
    error_message = "name must be 2-256 characters: lowercase letters and digits, optionally separated by '.', '_', '__' or hyphens, with '/' between namespace segments. Each segment starts and ends with a letter or digit."
  }
}

variable "image_tag_mutability" {
  description = "IMMUTABLE (default) rejects a push that reuses an existing tag, so a tag always identifies the same image. MUTABLE allows re-pushing a tag such as :latest."
  type        = string
  default     = "IMMUTABLE"
  nullable    = false

  validation {
    condition     = contains(["IMMUTABLE", "MUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be IMMUTABLE or MUTABLE."
  }
}

variable "force_delete" {
  description = "Allow Terraform to delete the repository while it still contains images. Keep false wherever images must survive a mistaken destroy."
  type        = bool
  default     = false
  nullable    = false
}

variable "scan_on_push" {
  description = "Repository-level basic scan on push. AWS is deprecating repository-level scanning settings in favour of the registry-level scanning configuration, which is account-wide and belongs in the root configuration, not in this module."
  type        = bool
  default     = true
  nullable    = false
}

variable "encryption_type" {
  description = "Encryption at rest: KMS (default) or AES256. Changing it replaces the repository and deletes its images."
  type        = string
  default     = "KMS"
  nullable    = false

  validation {
    condition     = contains(["KMS", "AES256"], var.encryption_type)
    error_message = "encryption_type must be KMS or AES256."
  }
}

variable "kms_key_arn" {
  description = "ARN of a customer managed KMS key. Null (default) uses the AWS managed key for ECR. Only valid with encryption_type = \"KMS\". Changing it replaces the repository and deletes its images."
  type        = string
  default     = null
}

variable "lifecycle_policy_json" {
  description = "Complete ECR lifecycle policy document as JSON. Null (default) builds the policy from the tagged_image_* and untagged_image_expiry_days inputs."
  type        = string
  default     = null

  validation {
    condition     = var.lifecycle_policy_json == null || can(jsondecode(var.lifecycle_policy_json))
    error_message = "lifecycle_policy_json must be valid JSON."
  }
}

variable "tagged_image_prefixes" {
  description = "Tag prefixes whose images the default lifecycle policy retains by count. Images whose tags match none of these prefixes are not expired by the tagged rule. Ignored when lifecycle_policy_json is set."
  type        = list(string)
  default     = ["v"]
  nullable    = false

  validation {
    condition     = length(var.tagged_image_prefixes) > 0 && alltrue([for p in var.tagged_image_prefixes : length(p) > 0])
    error_message = "tagged_image_prefixes must contain at least one non-empty prefix. To manage tagged images differently, set lifecycle_policy_json."
  }
}

variable "tagged_image_retention_count" {
  description = "Number of most recent images, with a tag matching tagged_image_prefixes, that the default lifecycle policy keeps. Ignored when lifecycle_policy_json is set."
  type        = number
  default     = 10
  nullable    = false

  validation {
    condition     = var.tagged_image_retention_count >= 1 && floor(var.tagged_image_retention_count) == var.tagged_image_retention_count
    error_message = "tagged_image_retention_count must be a whole number of at least 1."
  }
}

variable "untagged_image_expiry_days" {
  description = "Days after push after which the default lifecycle policy expires untagged images. Ignored when lifecycle_policy_json is set."
  type        = number
  default     = 7
  nullable    = false

  validation {
    condition     = var.untagged_image_expiry_days >= 1 && floor(var.untagged_image_expiry_days) == var.untagged_image_expiry_days
    error_message = "untagged_image_expiry_days must be a whole number of at least 1."
  }
}

variable "create_repository_policy" {
  description = "Attach repository_policy_json as the repository policy. A separate flag, rather than a null check on the JSON, so the decision is known at plan time even when the policy names resources created in the same apply."
  type        = bool
  default     = false
  nullable    = false
}

variable "repository_policy_json" {
  description = "Repository policy as JSON, for example to let other accounts pull. Used only when create_repository_policy is true. With no repository policy (the default), only IAM principals in the owning account with ECR permissions have access."
  type        = string
  default     = null

  validation {
    condition     = var.repository_policy_json == null || can(jsondecode(var.repository_policy_json))
    error_message = "repository_policy_json must be valid JSON."
  }
}

variable "tags" {
  description = "Tags for the repository. A Name tag equal to var.name is added unless this map sets Name. Tags from the provider's default_tags are applied by the provider as usual."
  type        = map(string)
  default     = {}
  nullable    = false
}
