output "role_arns" {
  description = "Map of environment -> IAM role ARN. Set the 'testing' ARN as the terraform repo's AWS_TESTING_ROLE_ARN secret; use 'production' for the app repo's deploy."
  value       = { for env, role in aws_iam_role.env : env => role.arn }
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider used by the roles."
  value       = local.oidc_provider_arn
}
