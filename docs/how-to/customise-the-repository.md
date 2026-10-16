# How to customise the repository

## Keep a different number of images

Change the default lifecycle policy's inputs:

```hcl
module "ecr_repository" {
  # ...
  tagged_image_prefixes        = ["release-"]
  tagged_image_retention_count = 30
  untagged_image_expiry_days   = 3
}
```

## Write your own lifecycle policy

Build it with the provider's `aws_ecr_lifecycle_policy_document` data source or with
`jsonencode`, and pass it whole:

```hcl
module "ecr_repository" {
  # ...
  lifecycle_policy_json = data.aws_ecr_lifecycle_policy_document.this.json
}
```

List rules in ascending `rulePriority`, otherwise the provider plans to recreate the
policy on every run. A rule with `tagStatus = "any"` must have the highest priority
number.

## Let other accounts pull

Build the policy with `aws_iam_policy_document`, pass its `json`, and set the flag.
The policy may name roles created in the same apply:

```hcl
module "ecr_repository" {
  # ...
  create_repository_policy = true
  repository_policy_json   = data.aws_iam_policy_document.cross_account_pull.json
}
```

[`examples/complete`](../../examples/complete) has a working policy.

## Use your own KMS key

Pass `kms_key_arn` when you create the repository. Changing it later replaces the
repository and deletes its images. The principal that creates the repository needs
`kms:CreateGrant`, `kms:RetireGrant` and `kms:DescribeKey` on the key;
`kms:RetireGrant` must be in that principal's IAM policy.

## Configure registry-wide scanning or replication

Add the account-wide resources (`aws_ecr_registry_scanning_configuration`,
`aws_ecr_replication_configuration`) to your root configuration next to the module
call, once per account and Region.
