# Design decisions

## One repository per call

The module manages one repository and the two policies attached to it. Anything that
exists once per account and Region — registry scanning, replication, pull-through
caches, the registry policy — stays out, because two calls of a per-repository module
would overwrite each other's settings.

## Immutable tags by default

A tag that can be re-pushed can silently change what a deployment runs. Immutable
tags make a tag a promise. Workflows that re-push `:latest` can opt out, and should
then deploy by digest.

## A lifecycle policy is always attached

A repository without one keeps every image forever and its cost only grows. The
default keeps a fixed number of release-tagged images and expires untagged layers
quickly; callers with other conventions pass their own policy.

## Changes that replace the repository

The AWS provider replaces the repository when `name`, `encryption_type` or
`kms_key_arn` changes: AWS does not allow the encryption settings of an existing
repository to change. Replacement deletes the images, or fails while
`force_delete = false` and images remain — which is why `force_delete` is off by
default. Every change to the lifecycle policy also replaces the
`aws_ecr_lifecycle_policy` object; that is harmless, because it is recreated at once.

## The policy flag

`create_repository_policy` is a separate boolean, not a null check on
`repository_policy_json`, because the policy often names roles created in the same
apply. Its value is then unknown at plan time and cannot decide whether the policy
resource exists.

## Resource names are `main`

They match the in-repository module this one came from, so its callers migrate with
no `moved` blocks. Renaming them would be a breaking change.

## Left out on purpose

| Not included | Why |
| --- | --- |
| Registry-level scanning, replication, pull-through cache | Account-wide: configure once in the root configuration |
| IAM roles for pushers and pullers | Identities belong to the workloads; grant with `repository_arn` |
| `IMMUTABLE_WITH_EXCLUSION` tag mutability | Needs AWS provider 6.8 or later; a minor release when a caller needs it |
| Creating KMS keys | Keys are managed where an organisation keeps its keys |
