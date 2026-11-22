# software-factory-example-terraform

A Terraform **module library** built by its own software factory. It exposes **one public module** (`modules/public/app`) consumed by `software-factory-example-python`; implementation modules live in `modules/private/*`. This repo owns **no persistent infrastructure** — it only ever `apply`s **ephemerally** to test modules, then destroys them.

Read these before proposing changes, and use their terms exactly:

- [`GLOSSARY.md`](GLOSSARY.md) — this repo's vocabulary (shared factory terms live in the home repo).
- [`docs/adr/`](docs/adr/) — Architecture Decision Records (start with [`0001`](docs/adr/0001-public-private-module-contract.md)).
- [`docs/factory/SPEC.md`](docs/factory/SPEC.md) — the factory for this repo (to be scaffolded).
- Shared vocabulary & skills: the **home repo** (`../software-factory-example-home-repo`).

## Module layout

```
modules/
├── public/
│   └── app/          ← the ONLY consumable module; the supported contract
└── private/
    ├── lambda/
    ├── dynamodb/
    └── eventbridge/  ← internal; composed by public/app via ../../private/<name>
```

Consumers pin `git::https://github.com/EduardBargues/software-factory-example-terraform.git//modules/public/app?ref=vX.Y.Z`. Never point a consumer at `modules/private/*`.

## Brakes & testing

- **Per-PR (no cloud creds):** `terraform fmt -check`, `terraform validate`, `tflint`, **Checkov**, `gitleaks`, and native `terraform test` with `mock_provider`.
- **On-demand e2e (PR label `run-e2e`):** real **ephemeral apply** of `examples/` + **Terratest** assertions against live resources, then `destroy` — in a dedicated sandbox AWS account via OIDC short-lived creds. Never a merge gate by default; never nightly.

## Working agreement

- Claude-only this iteration: steer with `CLAUDE.md`, not `AGENTS.md`.
- Agents must commit *through* the brakes (never `--no-verify`) and must not edit `.github/`, pre-commit config, or `.config/`.
