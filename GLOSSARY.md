# Glossary — Terraform module library

Repo-specific vocabulary for `software-factory-example-terraform`. Shared factory terms live in the home repo's [`GLOSSARY.md`](../software-factory-example-home-repo/GLOSSARY.md); only terms unique to this repo belong here.

## Modules

- **Public module** — the single consumable module, `modules/public/app`; the supported interface this repo exposes. _Avoid: root module, main module._
- **Private module** — an implementation module under `modules/private/*` (lambda, dynamodb, eventbridge…), composed by the public module via relative path; **not for direct consumption**. "Private" is by convention, not enforced. _Avoid: submodule (ambiguous with git submodules), internal._
- **App module** — the specific public module `modules/public/app`: a flexible composition covering the app's infrastructure requirements.
- **Example** — a Terraform config under `examples/` that instantiates the public module for testing; the only thing this repo ever `apply`s.
- **Repo-wide tag** — a semver tag (`vX.Y.Z`) covering the whole repo; the version a consumer pins via `?ref=`. One public module means per-module tags are unnecessary.

## Testing & apply

- **Ephemeral apply** — a test that `apply`s real infra from an `example`, asserts against it, then `destroy`s it whether the test passes or fails. This repo keeps **no persistent state**. _Avoid: deploy (that's the app repo's job)._
- **Native test** — a `*.tftest.hcl` run via `terraform test`; uses `mock_provider` for credential-free, plan-level checks in the per-PR brakes.
- **Mock provider** — a Terraform test provider returning synthetic data instead of calling the cloud API; no resources created, no creds.
- **Terratest** — the Go (`test/*_test.go`) framework (Gruntwork) that `apply`s an example against real AWS, asserts real behavior via the AWS SDK, and `defer`s destroy. Runs on-demand, not per-PR by default.
- **`run-e2e`** — the PR label that triggers the on-demand real-apply e2e run.
- **Environment** — one of `testing`, `staging`, `production`: the AWS resources tagged `environment=<name>` plus the IAM role (`terraform-<name>`) permitted — via ABAC — to touch only those. A single AWS account holds all three; the tag is the boundary (no separate accounts). _Avoid: sandbox._
- **testing** — where `run-e2e` applies ephemerally (apply → assert → destroy); no persistent resources.
- **staging** — where the app deploys on a PR (on-demand) and just after merging to main, before production.
- **production** — where the app deploys after staging.
- **Reaper** — a scheduled sweep that destroys resources leaked by a failed `destroy`.

## IaC brakes

- **tflint** — the Terraform linter brake.
- **Checkov** — the static security/compliance scanner brake (chosen over tfsec, which folded into Trivy).
