# RUNBOOK — operate and debug the Terraform factory

How to run and debug *this* factory. **Standing up the repo** (labels, secrets,
Anthropic WIF, branch protection, smoke test) is the same for every factory repo —
follow the hub's [**NEW-REPO-CHECKLIST**](https://github.com/EduardBargues/software-factory-example-home-repo/blob/main/docs/factory/NEW-REPO-CHECKLIST.md).

## Prerequisites (local dev)

Run **`./scripts/dev-setup.sh`** once — it installs the brake toolchain (Terraform
>= 1.7, tflint, Checkov, pre-commit; Go >= 1.26 for Terratest) and activates the
pre-commit hook. Keep hooks current with `pre-commit autoupdate` (verify the
`antonbabenko/pre-commit-terraform` rev).

## Secrets (repo-specific)

The generic factory secrets (`FACTORY_PAT`, the Anthropic WIF ids) are in the
checklist above; `scripts/setup-terraform-secrets.sh` automates them. **This** repo
also needs the AWS testing role for `run-e2e`: `AWS_TESTING_ROLE_ARN` (secret) and
`AWS_TESTING_REGION` (variable), produced by the bootstrap below. No long-lived
cloud keys — AWS is OIDC-only.

## Environments & OIDC roles (for run-e2e and deploy)

A **single** AWS account holds three environments — `testing`, `staging`,
`production` — separated by the **`environment` resource tag** (ABAC), not by
account. Each has an IAM role (`terraform-<env>`) that may only touch resources
tagged `environment=<env>`.

Create them **once, by hand, with admin credentials**, via the bootstrap root
module:

```bash
cd modules/private/github-oidc
terraform init
terraform apply            # add -var=create_oidc_provider=false if the provider exists
terraform output role_arns
```

This creates the GitHub OIDC provider and the three roles, each with a trust
policy constrained to the right repo/branch subject (see that module's
[`README.md`](../../modules/private/github-oidc/README.md)). Then set the
**testing** role ARN as `AWS_TESTING_ROLE_ARN` (the wizard does this); wire
**staging** / **production** to the app repo when its deploy tier lands.

> Resources a run creates MUST be tagged `environment=<env>` or the role denies the
> call. Add a scheduled **reaper** (e.g. aws-nuke on a tag/age filter) to sweep
> anything a failed `terraform destroy` leaks.

## Operating the pipeline

- **Start work**: open an issue. A collaborator-opened issue auto-gets `agent:explore`; otherwise add the label by hand.
- **Flow**: explore (verdict) → `agent:implement` (draft PR) → `agent:review` (fixes + marks ready) → **human merge**.
- **Real-apply e2e**: add the `run-e2e` label to a PR when a change needs real-deploy validation. It applies in testing, asserts, destroys, and comments the outcome.
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
