# software-factory-example-terraform

_One public module, applied ephemerally — the infrastructure half of the software factory._

A Terraform **module library**, built and tested by its own software factory — the
infrastructure half of a multi-repo software-factory setup. It exposes **one public
module** (`modules/public/app`) consumed by
[`software-factory-example-python`](https://github.com/EduardBargues/software-factory-example-python),
over private internals. It owns no persistent infrastructure — it only applies
**ephemerally** to test modules, then destroys them.

Canonical docs — read these before proposing changes, and use their terms exactly:

- [`CLAUDE.md`](CLAUDE.md) — module layout, brakes, testing, working agreement.
- [`docs/factory/SPEC.md`](docs/factory/SPEC.md) — the factory (pipeline + brakes + testing).
- [`docs/factory/RUNBOOK.md`](docs/factory/RUNBOOK.md) — operate and debug this factory.
- [`GLOSSARY.md`](GLOSSARY.md) — this repo's vocabulary (shared terms: the home repo).
- [`docs/adr/`](docs/adr/) — Architecture Decision Records.

## Part of a multi-repo factory

This repo is the **infrastructure** half of a three-repo setup. Shared agent skills, vocabulary, and the cross-repo setup guide live in the **home repo** ([`software-factory-example-home-repo`](https://github.com/EduardBargues/software-factory-example-home-repo)) — run *cross-repo* agent sessions from there, and see its [`NEW-REPO-CHECKLIST`](https://github.com/EduardBargues/software-factory-example-home-repo/blob/main/docs/factory/NEW-REPO-CHECKLIST.md) to stand up a new factory repo. The consumer is the app repo, [`software-factory-example-python`](https://github.com/EduardBargues/software-factory-example-python).

## Consuming the module

```hcl
module "app" {
  source = "git::https://github.com/EduardBargues/software-factory-example-terraform.git//modules/public/app?ref=vX.Y.Z"
  # ... inputs ...
}
```

Always pin `?ref=` to a release **tag**. Never point a consumer at `modules/private/*`.

## Status

Factory, brakes, and test harness are in place; **no real modules yet** — the first
`modules/public/app` composition lands when the app repo raises a requirement.

## Local development

Install the brake toolchain and activate the pre-commit hook once, so `git commit`
runs the same checks as CI:

```bash
./scripts/dev-setup.sh
```

It installs Terraform/tflint/Checkov/pre-commit as needed (via the repo-local
public-PyPI config in `.config/pip/`, not a token-gated private index) and runs
`pre-commit install`. After that, commits run fmt/validate/tflint/Checkov/gitleaks
+ native `terraform test` locally — before anything reaches CI.

## Agent skills

Shared skills are loaded at CI time from the home repo at the pinned `skills-lock.json`
ref (see [`docs/adr/0001`](docs/adr/0001-public-private-module-contract.md) and the
home repo's ADR-0002); they are not committed here.
