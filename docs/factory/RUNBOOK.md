# RUNBOOK — operate, set up, and debug the Terraform factory

## Prerequisites (local dev)

- **Terraform** >= 1.7 (for `mock_provider` in native tests), **tflint**, **Checkov**, **pre-commit**, and **Go** >= 1.26 (for Terratest).
- Install the hooks: `pre-commit install` then `pre-commit run --all-files`.
- Keep hooks current: `pre-commit autoupdate` (and verify the `antonbabenko/pre-commit-terraform` rev).

## Secrets & variables (GitHub repo settings)

Set these once the repo is on GitHub (Phase D). **No long-lived cloud keys** — AWS access is OIDC-only.

**Secrets**

- `FACTORY_PAT` — fine-grained, single-repo, expiring PAT. Lets tasks apply labels / open PRs so downstream workflows fire (the built-in `GITHUB_TOKEN` can't).
- `ANTHROPIC_FEDERATION_RULE_ID`, `ANTHROPIC_ORGANIZATION_ID`, `ANTHROPIC_SERVICE_ACCOUNT_ID`, `ANTHROPIC_WORKSPACE_ID` — Anthropic WIF identifiers (not credentials; useless without a valid GitHub OIDC token from this repo).
- `AWS_SANDBOX_ROLE_ARN` — the IAM role `run-e2e` assumes via OIDC in the sandbox account.

**Variables**

- `AWS_SANDBOX_REGION` — region for ephemeral e2e (defaults to `eu-west-1`).

## Sandbox AWS account (for run-e2e)

1. Use a **dedicated** account, isolated from prod/staging.
2. Create a GitHub OIDC identity provider + an IAM role whose trust policy is constrained to this repo's `sub` claim (`repo:EduardBargues/software-factory-example-terraform:*`).
3. Scope the role to **least privilege** — only the services the examples create (e.g. Lambda, IAM for the function role, CloudWatch Logs, DynamoDB, EventBridge as modules land).
4. Add a scheduled **reaper** (e.g. aws-nuke on a tag/age filter) to sweep resources a failed `terraform destroy` leaks.

> The OIDC role itself is foundational infra both factories need. It is the natural **first requirement-driven module** (`modules/private/oidc-github` or similar) once deploy work begins — until then, provision it by hand (a `wizard` is a good fit).

## Operating the pipeline

- **Start work**: open an issue. A collaborator-opened issue auto-gets `agent:explore`; otherwise add the label by hand.
- **Flow**: explore (verdict) → `agent:implement` (draft PR) → `agent:review` (fixes + marks ready) → **human merge**.
- **Real-apply e2e**: add the `run-e2e` label to a PR when a change needs real-deploy validation. It applies in the sandbox, asserts, destroys, and comments the outcome.
- **Rebase**: PRs are rebased daily; force one with the `agent:rebase` label.
- **Release a module version**: merge to main, then cut a repo-wide tag: `git tag vX.Y.Z && git push --tags`. Consumers bump their `?ref=`.

## Debugging

- A task failed? Open its **Actions** run logs. The harness redacts short-lived tokens and surfaces `claude` stdout/stderr on failure.
- Brakes failing locally but not in CI (or vice versa)? Ensure the same tool versions (`terraform version`, `tflint --version`, `checkov --version`) and run `pre-commit run --all-files`.
- `load-shared-skills` failing? Check `skills-lock.json` points at a ref that exists in the (public) home repo.
- e2e leaking resources? Check the reaper and the uniqueness of resource names in the test.

## Continuous improvement

Run `/retro` after a run that went wrong. Route each finding to a **check** (tflint rule / Checkov policy / native test) where possible, a **coding standard** only if genuinely fuzzy, or delete. Prefer pushing rules down to the deterministic brake.

## Hardening TODO (before going live)

- Pin the third-party setup actions (`hashicorp/setup-terraform`, `terraform-linters/setup-tflint`, `actions/setup-python`, `actions/setup-go`, `aws-actions/configure-aws-credentials`) to full commit SHAs, matching how `checkout`/`github-script` are pinned.
- Move the `skills-lock.json` pin from the bootstrap home-repo SHA to a released home-repo **tag**.
- Turn on branch protection (require the `brakes` check; require a human review).
