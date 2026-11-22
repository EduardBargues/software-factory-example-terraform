# SPEC — the Terraform module-library factory

The agent pipeline that builds and tests this repo. It mirrors the app repo's
factory (`software-factory-example-python`) and adapts the brakes and testing for
Infrastructure-as-Code. For the system-wide multi-repo design, see the home repo's
`docs/factory/SPEC.md`.

## What this repo is

A Terraform **module library**. It exposes exactly one public module
(`modules/public/app`) composed of private internals (`modules/private/*`), and is
consumed by the app repo via pinned git sources. It owns **no persistent
infrastructure** — it only applies infra **ephemerally** to test modules, then
destroys it. See [`docs/adr/0001`](../adr/0001-public-private-module-contract.md).

## The pipeline (parity with the app repo)

| Task | Trigger | Mode | Does |
|---|---|---|---|
| **auto-label** | issue opened | — | collaborator gate → applies `agent:explore` via FACTORY_PAT |
| **explore** | `agent:explore` | read-only | posts a ~20-line verdict; auto-applies `agent:implement` on `easy-call` |
| **implement** | `agent:implement` | write | builds the change, commits through the brakes, opens a draft PR, applies `agent:review` |
| **review** | `agent:review` (PR) | write | two-axis review (standards + spec), fixes what's safe, marks ready |
| **human merge** | — | human | the v1 gate that always stays manned |
| **run-e2e** | `run-e2e` (PR) | write (cloud) | ephemeral real-apply + Terratest in the sandbox, then destroy |
| **morning-rebase** | daily / `agent:rebase` | — | keep open PRs rebased onto main |

Auth and prompt-injection defenses are identical to the app repo: a single
swappable harness (`.github/actions/run-agent`), GitHub OIDC → Anthropic WIF (no
stored keys), untrusted issue/PR text staged to a file (never interpolated), and a
triage+ collaborator re-check on every triggered run.

## Shared skills

Skills are **not** committed here. Before an agent runs, `.github/actions/load-shared-skills`
checks out the home repo at the ref pinned in `skills-lock.json` and copies its
`.claude/skills/` into the working tree (home ADR-0002). Bumping the pin is a PR.

## Brakes (the first brake)

**Per-PR, credential-free** (`.pre-commit-config.yaml` + `ci.yml`):

- `terraform fmt -check`, `terraform validate`, `tflint`, **Checkov** (security/compliance), `gitleaks`, base hygiene hooks, `actionlint`.
- Native **`terraform test`** with `mock_provider` — plan-level unit/contract tests per module, in seconds, no cloud.

The agent commits **through** these (never `--no-verify`) and must not edit
`.github/`, `.pre-commit-config.yaml`, or `CODING_STANDARDS.md`.

## Testing layers

- **Native tests** (`modules/*/tests/*.tftest.hcl`, `command = plan` + mocks) — the per-PR gate. Fast, no creds.
- **Terratest** (`test/*_test.go`) — real **ephemeral** apply of an `examples/` instance, assert via AWS SDK, destroy. On-demand only via the `run-e2e` label; OIDC short-lived creds into a scoped role in a dedicated **sandbox** account. Not a default merge gate; never scheduled.

## Module contract & distribution

- One public module: `modules/public/app`. Internals in `modules/private/*`, composed by relative path.
- Consumed as `git::https://github.com/EduardBargues/software-factory-example-terraform.git//modules/public/app?ref=vX.Y.Z`.
- Release = a **repo-wide** semver tag `vX.Y.Z`. No registry. (If the library ever grows many public modules/consumers, revisit: per-module tags or a private registry.)

## Day-one state

Factory + brakes + test harness are **live**; `modules/`, `examples/`, and `test/`
are **skeletons with no real modules**. The first real `modules/public/app`
composition lands when the app repo raises a requirement. Until then, native tests
and Terratest are no-ops (CI reports "module-empty" and skips cleanly).

## Deploy model (who applies what)

- **This repo**: ephemeral test applies only (apply → assert → destroy).
- **App repo**: the *persistent* deploy of the real app — it consumes the pinned module and owns `apply` / apply-before-merge. Lambda via keyless OIDC, requirement-driven.
