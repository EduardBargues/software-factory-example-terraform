# Bootstrap: GitHub OIDC provider + one tag-scoped (ABAC) role per environment.
#
# This is BOOTSTRAP, not part of the module-library contract. It creates
# PERSISTENT IAM resources and is applied ONCE, BY HAND, with admin AWS
# credentials (see README.md). The module-library CI never applies this.
#
# After apply, CI assumes these roles keylessly via OIDC — no long-lived keys.

terraform {
  required_version = ">= 1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
  # State is local by default (one-off bootstrap). For a team, create a remote
  # backend (e.g. an S3 bucket + DynamoDB lock) first, then configure it here.
}

provider "aws" {
  region = var.region
}

# ── GitHub OIDC identity provider (one per account) ───────────────────────────
# Fetch GitHub's current CA fingerprint rather than hardcoding a thumbprint.
data "tls_certificate" "github" {
  count = var.create_oidc_provider ? 1 : 0
  url   = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github" {
  count           = var.create_oidc_provider ? 1 : 0
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github[0].certificates[0].sha1_fingerprint]
}

# If the provider already exists in the account, set create_oidc_provider=false
# and we look it up instead.
data "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 0 : 1
  url   = "https://token.actions.githubusercontent.com"
}

locals {
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.github[0].arn
}

# ── One role per environment, scoped by the `environment` resource tag (ABAC) ─
resource "aws_iam_role" "env" {
  for_each = var.environments

  name        = "terraform-${each.key}"
  description = "Assumed by GitHub Actions via OIDC; may only touch resources tagged environment=${each.key}."

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = local.oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = each.value.allowed_subs
        }
      }
    }]
  })

  tags = {
    environment = each.key
    managed-by  = "github-oidc-bootstrap"
  }
}

# Writes/creates: ADMIN (Action "*") but gated by the `environment` tag, so each
# role can manage ANY resource type — as long as it's tagged (or tagged on create)
# for its own environment. No per-service maintenance.
#
# LIMITATION (inherent to single-account tag ABAC): a mutating action is allowed
# only where AWS supports the tag condition key. Resource types that can't be
# tagged on create (no `aws:RequestTag`) or don't honor `aws:ResourceTag` will be
# denied — add a narrow exception for those, or split environments into separate
# accounts for a hard boundary. Every resource a run creates MUST carry
# tags = { environment = "<env>" } or the create is denied.
resource "aws_iam_role_policy" "env" {
  # The broad grant below is INTENTIONAL: admin scoped to the environment tag
  # (ABAC), with the env tag as the only boundary (see README). These Checkov
  # checks are accepted knowingly — tighten production later if warranted.
  #checkov:skip=CKV_AWS_62:Intentional admin-within-environment-tag (ABAC); boundary is the env tag
  #checkov:skip=CKV_AWS_63:Action "*" is deliberate and gated by aws:ResourceTag/RequestTag environment
  #checkov:skip=CKV2_AWS_40:Full IAM is deliberate and env-tag-scoped; needed to manage the function execution role
  for_each = var.environments

  name = "admin-${each.key}"
  role = aws_iam_role.env[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AdminOnResourcesTaggedForThisEnv"
        Effect    = "Allow"
        Action    = "*"
        Resource  = "*"
        Condition = { StringEquals = { "aws:ResourceTag/environment" = each.key } }
      },
      {
        Sid       = "AdminCreateWhenTaggingForThisEnv"
        Effect    = "Allow"
        Action    = "*"
        Resource  = "*"
        Condition = { StringEquals = { "aws:RequestTag/environment" = each.key } }
      },
    ]
  })
}

# Reads/plan: Terraform must refresh state, and most read actions can't be
# tag-gated. Attach AWS's managed ReadOnlyAccess (AWS keeps it current) so plan
# works across services. Reads are account-wide (not tag-scoped) but non-mutating.
resource "aws_iam_role_policy_attachment" "readonly" {
  for_each = var.environments

  role       = aws_iam_role.env[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
