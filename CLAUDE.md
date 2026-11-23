# software-factory-example-terraform

A Terraform **module library** built by its own software factory. It exposes **one public module** (`modules/public/app`) consumed by `software-factory-example-python`; implementation modules live in `modules/private/*`. This repo owns **no persistent infrastructure** — it only ever `apply`s **ephemerally** to test modules, then destroys them.

Read these before proposing changes, and use their terms exactly:

- [`GLOSSARY.md`](GLOSSARY.md) — this repo's vocabulary (shared factory terms live in the home repo).
- [`docs/adr/`](docs/adr/) — Architecture Decision Records (start with [`0001`](docs/adr/0001-public-private-module-contract.md)).
- [`docs/factory/SPEC.md`](docs/factory/SPEC.md) — the factory (pipeline, brakes, testing).
- [`docs/factory/RUNBOOK.md`](docs/factory/RUNBOOK.md) — operate & debug this factory.

## The multi-repo factory

Part of a three-repo setup (home-repo ADR-0001):

- **Hub** — [`software-factory-example-home-repo`](https://github.com/EduardBargues/software-factory-example-home-repo) (`../software-factory-example-home-repo`; clone if missing). **Read its `CLAUDE.md` to understand — or answer questions about — the whole factory** (brakes, accelerators, topology). Shared skills/vocab/reusable-workflows live there, pinned by tag.
- **Consumed by** [`software-factory-example-python`](https://github.com/EduardBargues/software-factory-example-python) — the app repo pins this repo's `modules/public/app` at a tag.

## Module contract

One public module (`modules/public/app`) over private internals; consumers pin a tagged `git::…//modules/public/app?ref=` source and never reference `modules/private/*`. See [`docs/adr/0001`](docs/adr/0001-public-private-module-contract.md) + the module READMEs.

## Brakes & testing

Defined in [`.pre-commit-config.yaml`](.pre-commit-config.yaml) + [`.github/workflows/ci.yml`](.github/workflows/ci.yml) (per-PR, no cloud creds) and [`.github/workflows/run-e2e.yml`](.github/workflows/run-e2e.yml) (on-demand real-apply e2e; PR label `run-e2e`). Vocabulary: [`GLOSSARY.md`](GLOSSARY.md).

## Working agreement

- Claude-only this iteration: steer with `CLAUDE.md`, not `AGENTS.md`.
- Agents must commit *through* the brakes (never `--no-verify`) and must not edit `.github/`, pre-commit config, or `.config/`.
