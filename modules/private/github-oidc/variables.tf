variable "region" {
  description = "AWS region for the provider (IAM is global; region is just for the provider session)."
  type        = string
  default     = "eu-west-1"
}

variable "create_oidc_provider" {
  description = "Create the GitHub OIDC provider. Set to false if one already exists in this account."
  type        = bool
  default     = true
}

variable "environments" {
  description = <<-EOT
    One IAM role per environment. `allowed_subs` are the GitHub OIDC `sub`
    patterns (immutable-subject format) allowed to assume the role. Trust mapping
    follows the deploy flow:
      - testing    — the terraform module library's own ephemeral run-e2e.
      - staging    — the app repo deploys here on a PR (on-demand) AND just after
                     merging to main (pre-production).
      - production — the app repo deploys here only after merging to main.
  EOT
  type = map(object({
    allowed_subs = list(string)
  }))
  default = {
    testing = {
      allowed_subs = [
        "repo:EduardBargues@6433629/software-factory-example-terraform@1467895257:*",
      ]
    }
    staging = {
      allowed_subs = [
        "repo:EduardBargues@6433629/software-factory-example-python@1464289503:pull_request",
        "repo:EduardBargues@6433629/software-factory-example-python@1464289503:ref:refs/heads/main",
      ]
    }
    production = {
      allowed_subs = [
        "repo:EduardBargues@6433629/software-factory-example-python@1464289503:ref:refs/heads/main",
      ]
    }
  }
}
