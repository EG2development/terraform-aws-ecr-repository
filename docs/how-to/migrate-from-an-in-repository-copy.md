# How to migrate from an in-repository copy

If your project has its own copy of this module (inputs `repository_name` and
`project_name`, resources `aws_ecr_repository.main` and
`aws_ecr_lifecycle_policy.main`), you can move to the released module without
replacing anything. The resource names inside the module are the same, so resource
addresses do not change and no `moved` block is needed.

1. Change `source` to the pinned Git source and rename two arguments:

   | Old argument | New argument |
   | --- | --- |
   | `repository_name` | `name` |
   | `project_name` | Removed. Pass `tags = { Project = <value>, ManagedBy = "terraform" }` to keep the tags the copy set |

2. Run `terraform init`, then `terraform plan`.
3. The plan must show no change to the repository or its lifecycle policy. If it
   proposes any, stop and compare your inputs with the table above, in particular the
   tags.
4. Merge. Nothing needs applying: state records resource addresses, not where the
   module's code came from.

To go back, restore the old `source` and arguments; the plan again shows no change.
