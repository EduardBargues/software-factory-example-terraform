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

data "aws_caller_identity" "current" {}

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

resource "aws_iam_role_policy" "env" {
  for_each = var.environments

  name = "abac-${each.key}"
  role = aws_iam_role.env[each.key].id

  # STARTER ABAC policy — validate and tighten per the services your modules
  # actually use. The `environment` tag is the ONLY boundary here (single
  # account), so correctness matters: every resource a run creates MUST carry
  # tags = { environment = "<env>" } or the run will be denied.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadOnlyDiscovery"
        Effect = "Allow"
        Action = [
          "lambda:Get*", "lambda:List*",
          "dynamodb:Describe*", "dynamodb:List*",
          "events:Describe*", "events:List*",
          "logs:Describe*", "logs:Get*", "logs:List*",
          "iam:Get*", "iam:List*",
          "sts:GetCallerIdentity",
        ]
        Resource = "*"
      },
      {
        Sid       = "MutateResourcesTaggedForThisEnv"
        Effect    = "Allow"
        Action    = ["lambda:*", "dynamodb:*", "events:*", "logs:*"]
        Resource  = "*"
        Condition = { StringEquals = { "aws:ResourceTag/environment" = each.key } }
      },
      {
        Sid       = "CreateOnlyWhenTaggedForThisEnv"
        Effect    = "Allow"
        Action    = ["lambda:*", "dynamodb:*", "events:*", "logs:*"]
        Resource  = "*"
        Condition = { StringEquals = { "aws:RequestTag/environment" = each.key } }
      },
      {
        Sid    = "IamForFunctionExecutionRole"
        Effect = "Allow"
        Action = [
          "iam:CreateRole", "iam:DeleteRole", "iam:GetRole", "iam:PassRole",
          "iam:AttachRolePolicy", "iam:DetachRolePolicy",
          "iam:PutRolePolicy", "iam:DeleteRolePolicy",
          "iam:TagRole", "iam:UntagRole",
          "iam:ListRolePolicies", "iam:ListAttachedRolePolicies",
        ]
        # Scope IAM to a per-env role-name prefix; your modules must name the
        # function's execution role "<env>-...".
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${each.key}-*"
      },
    ]
  })
}
