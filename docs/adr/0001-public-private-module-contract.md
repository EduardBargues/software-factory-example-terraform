# ADR-0001 — Single public module over private internals, distributed via pinned git sources

- **Status:** Accepted
- **Date:** 2026-11-22

## Situation

This repo is a Terraform **module library** consumed by `software-factory-example-python`. We must decide (1) what surface consumers depend on, and (2) how modules are distributed and versioned.

## Options

**Consumption surface**
- **(a) Expose every module** — consumers compose `lambda`, `dynamodb`, `eventbridge` directly. Maximum flexibility, but consumers couple to our internals and we can't refactor without breaking them.
- **(b) One public composition module** — expose a single `modules/public/app`; keep implementation modules in `modules/private/*`. Stable contract, free to refactor internals.

**Distribution**
- Public Terraform Registry — **forbids this repo shape**: one module per repo, mandated `terraform-<provider>-<name>` naming.
- Private registry (HCP / Spacelift / Scalr) — supports monorepos, but is standing infra/cost for a single consumer.
- **Native git sources** — `git::…//modules/public/app?ref=<tag>`, zero infra.

## Choice

**(b) + native git sources.** The repo exposes exactly one consumable module, **`modules/public/app`**, flexible enough to cover the app's requirements, which internally composes nested implementation modules under **`modules/private/*`** (referenced by relative path). The python repo pins **only** `git::https://github.com/EduardBargues/software-factory-example-terraform.git//modules/public/app?ref=<tag>`. Versioning is **repo-wide semver tags** (`vX.Y.Z`) — one public module means no per-module tagging is needed. No registry.

## Why

- **Encapsulation.** A single public contract lets us restructure `private/*` freely without breaking the consumer. "Private" is by convention (a public repo's files are all readable), but the `public/`–`private/` split makes the supported surface unmistakable.
- **Registry constraints.** The public registry can't host a multi-module repo at all; a private registry is needless overhead for one consumer.
- **Auditable pins.** A version bump is a one-line, reviewable `?ref=` diff in the consumer — the git-source property we want.

## Consequences

- The consumer depends on the `modules/public/app` interface contract; changing that contract is a breaking (major) release. This cross-consumer reversal cost is why this decision is recorded.
- No `~>` version ranges (git sources pin exact refs); bumps are deliberate and manual.
- If the library ever gains many public modules or many consumers, revisit: adopt per-module tags (`techpivot/terraform-module-releaser`) or a private registry.
