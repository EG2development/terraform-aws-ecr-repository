output "repository_url" {
  description = "Push and pull images here."
  value       = module.ecr_repository.repository_url
}

output "repository_arn" {
  description = "Use in IAM policies that grant access to the repository."
  value       = module.ecr_repository.repository_arn
}
