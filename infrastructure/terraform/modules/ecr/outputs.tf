
output "repository_names" {
  description = "Names of all ECR repositories"
  value = {
    for name, repository in aws_ecr_repository.this :
    name => repository.name
  }
}

output "repository_urls" {
  description = "URLs used to push and pull container images"
  value = {
    for name, repository in aws_ecr_repository.this :
    name => repository.repository_url
  }
}

output "repository_arns" {
  description = "ARNs of all ECR repositories"
  value = {
    for name, repository in aws_ecr_repository.this :
    name => repository.arn
  }
}
