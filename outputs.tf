output "repository_name" {
  description = "Name of the repository."
  value       = aws_ecr_repository.main.name
}

output "repository_arn" {
  description = "ARN of the repository, for IAM policies that grant push or pull."
  value       = aws_ecr_repository.main.arn
}

output "repository_url" {
  description = "URL of the repository, in the form {registry}.dkr.ecr.{region}.amazonaws.com/{name}. Append :{tag} or @{digest} to address an image."
  value       = aws_ecr_repository.main.repository_url
}

output "registry_id" {
  description = "ID of the registry that holds the repository (the owning AWS account)."
  value       = aws_ecr_repository.main.registry_id
}
