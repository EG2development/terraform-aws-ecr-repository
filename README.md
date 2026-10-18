# terraform-aws-ecr-repository

A Terraform module for one private Amazon ECR repository with secure defaults:
immutable tags, scan on push, KMS encryption at rest, and a lifecycle policy that
stops old images from accumulating. You can use it without knowing anything about
the project it came from.

It deliberately does **not** manage:

- **Registry-level settings** — the registry scanning configuration (for example
  Amazon Inspector enhanced scanning), replication, pull-through cache rules and the
  registry policy. Each exists once per account and Region, so two calls to a
  per-repository module would overwrite each other. Configure them once in your root
  configuration.
- **IAM identities that push or pull.** Grant access in your own IAM policies using
  the `repository_arn` output, or give other accounts access through
  `create_repository_policy` and `repository_policy_json`.
- **Provider configuration and state.** There is no `provider` or `backend` block.

## Usage

```hcl
module "ecr_repository" {
  source = "git::https://github.com/EG2development/terraform-aws-ecr-repository.git?ref=v1.0.0" # x-release-please-version

  name = "team/service"

  tags = {
    Team = "platform"
  }
}
```

Pin `?ref=` to a release tag (inside the organisation) or the release's full commit
SHA (outside it), never to a branch. Run `terraform init` after changing `source`.
Reading a private module repository from a workstation or CI is set up once per
consuming repository:
[upgrade-module-version.md, step 0](https://github.com/EG2development/terraform-module-standards/blob/main/docs/runbooks/upgrade-module-version.md).

## Examples

| Example | Shows |
| --- | --- |
| [`examples/basic`](examples/basic) | The smallest useful call |
| [`examples/complete`](examples/complete) | A customer managed key, a custom lifecycle policy, and cross-account pull |

## Documentation

| You want to | Read |
| --- | --- |
| Create a repository and push your first image | [Tutorial: push your first image](docs/tutorials/push-your-first-image.md) |
| Change lifecycle rules, allow cross-account pull or use your own key | [How to customise the repository](docs/how-to/customise-the-repository.md) |
| Move from your own copy of this module without replacing anything | [How to migrate from an in-repository copy](docs/how-to/migrate-from-an-in-repository-copy.md) |
| Look up every resource, name and permission | [Reference: resources and permissions](docs/reference/resources-and-permissions.md) |
| See the resources and how they connect, on one page | [Architecture diagram](docs/reference/architecture.png) |
| Understand why it is built this way | [Design decisions](docs/explanation/design-decisions.md) |

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.16.0 |
| aws | >= 5.0 |

## Providers

| Name | Version |
| ---- | ------- |
| aws | >= 5.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_ecr_lifecycle_policy.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy) | resource |
| [aws_ecr_repository.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_ecr_repository_policy.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| name | Name of the ECR repository. May contain a namespace, for example "team/service". Changing it replaces the repository and deletes its images. | `string` | n/a | yes |
| create\_repository\_policy | Attach repository\_policy\_json as the repository policy. A separate flag, rather than a null check on the JSON, so the decision is known at plan time even when the policy names resources created in the same apply. | `bool` | `false` | no |
| encryption\_type | Encryption at rest: KMS (default) or AES256. Changing it replaces the repository and deletes its images. | `string` | `"KMS"` | no |
| force\_delete | Allow Terraform to delete the repository while it still contains images. Keep false wherever images must survive a mistaken destroy. | `bool` | `false` | no |
| image\_tag\_mutability | IMMUTABLE (default) rejects a push that reuses an existing tag, so a tag always identifies the same image. MUTABLE allows re-pushing a tag such as :latest. | `string` | `"IMMUTABLE"` | no |
| kms\_key\_arn | ARN of a customer managed KMS key. Null (default) uses the AWS managed key for ECR. Only valid with encryption\_type = "KMS". Changing it replaces the repository and deletes its images. | `string` | `null` | no |
| lifecycle\_policy\_json | Complete ECR lifecycle policy document as JSON. Null (default) builds the policy from the tagged\_image\_* and untagged\_image\_expiry\_days inputs. | `string` | `null` | no |
| repository\_policy\_json | Repository policy as JSON, for example to let other accounts pull. Used only when create\_repository\_policy is true. With no repository policy (the default), only IAM principals in the owning account with ECR permissions have access. | `string` | `null` | no |
| scan\_on\_push | Repository-level basic scan on push. AWS is deprecating repository-level scanning settings in favour of the registry-level scanning configuration, which is account-wide and belongs in the root configuration, not in this module. | `bool` | `true` | no |
| tagged\_image\_prefixes | Tag prefixes whose images the default lifecycle policy retains by count. Images whose tags match none of these prefixes are not expired by the tagged rule. Ignored when lifecycle\_policy\_json is set. | `list(string)` | <pre>[<br/>  "v"<br/>]</pre> | no |
| tagged\_image\_retention\_count | Number of most recent images, with a tag matching tagged\_image\_prefixes, that the default lifecycle policy keeps. Ignored when lifecycle\_policy\_json is set. | `number` | `10` | no |
| tags | Tags for the repository. A Name tag equal to var.name is added unless this map sets Name. Tags from the provider's default\_tags are applied by the provider as usual. | `map(string)` | `{}` | no |
| untagged\_image\_expiry\_days | Days after push after which the default lifecycle policy expires untagged images. Ignored when lifecycle\_policy\_json is set. | `number` | `7` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| registry\_id | ID of the registry that holds the repository (the owning AWS account). |
| repository\_arn | ARN of the repository, for IAM policies that grant push or pull. |
| repository\_name | Name of the repository. |
| repository\_url | URL of the repository, in the form {registry}.dkr.ecr.{region}.amazonaws.com/{name}. Append :{tag} or @{digest} to address an image. |
<!-- END_TF_DOCS -->

## Defaults and security decisions

| Decision | Default | Why | How to change it |
| --- | --- | --- | --- |
| Tags are immutable | `IMMUTABLE` | A tag always names the same image, so a deployment pinned to a tag cannot silently change | `image_tag_mutability = "MUTABLE"` for workflows that re-push a tag such as `:latest`. Pin deployments by digest if you do |
| Images are scanned on push | `true` | Basic vulnerability findings from the first push, at no extra configuration | `scan_on_push = false`. AWS is deprecating repository-level scan settings in favour of the registry-level scanning configuration, which you manage in your root configuration |
| Encrypted with KMS | AWS managed key `aws/ecr` | KMS encryption with no key to manage | `kms_key_arn` for a customer managed key, or `encryption_type = "AES256"` |
| Old images expire | Keep 10 images tagged `v*`; expire untagged images after 7 days | A repository without a lifecycle policy keeps every image indefinitely | The `tagged_image_*` inputs, or your own `lifecycle_policy_json` |
| No repository policy | None | Access stays with IAM principals in the owning account | `create_repository_policy = true` with `repository_policy_json` |
| Deletion is guarded | `force_delete = false` | Terraform refuses to delete a repository that still holds images | `force_delete = true` for short-lived environments |

Changing `name`, `encryption_type` or `kms_key_arn` replaces the repository and
deletes its images; see [design decisions](docs/explanation/design-decisions.md).

## Security scanning

Checkov runs on every pull request. No checks are skipped.

## Upgrading

Read [`CHANGELOG.md`](CHANGELOG.md) for every version between yours and the new one,
change `?ref=`, run `terraform init`, and review the plan. A minor or patch release
plans no changes unless you opt into something new. Moving from an in-repository copy:
[how-to](docs/how-to/migrate-from-an-in-repository-copy.md).

## Versioning and releases

Semantic versions, tags `vMAJOR.MINOR.PATCH`, created by release-please from
Conventional Commit pull-request titles. Patch: a fix that changes no plan. Minor: a
new optional input, output or off-by-default resource. Major: anything that can
change or replace an existing caller's resources, or raise a minimum version.
Details: [the standard](https://github.com/EG2development/terraform-module-standards/blob/main/docs/standard.md).

## Contributing and ownership

See [`CONTRIBUTING.md`](CONTRIBUTING.md). The team in
[`.github/CODEOWNERS`](.github/CODEOWNERS) reviews every change and owns releases.
Report vulnerabilities as described in [`SECURITY.md`](SECURITY.md).
