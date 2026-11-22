# `app` — the public module (the supported contract)

This is the **only** consumable module in this repository. The app repo
(`software-factory-example-python`) depends on exactly this interface:

```hcl
module "app" {
  source = "git::https://github.com/EduardBargues/software-factory-example-terraform.git//modules/public/app?ref=vX.Y.Z"
  # ... inputs ...
}
```

It is a flexible composition that, under the hood, wires together the private
implementation modules in [`../../private/`](../../private/) (e.g. lambda,
dynamodb, eventbridge) via relative `source` paths. Consumers must **never**
point at a `modules/private/*` module directly — that is a contract violation
(see [`docs/adr/0001`](../../../docs/adr/0001-public-private-module-contract.md)).

## Status

**Empty on purpose.** No resources are defined yet. The first real composition
lands when the app repo raises a requirement (see
[`docs/factory/SPEC.md`](../../../docs/factory/SPEC.md)). When it does, this
module ships with `variables.tf`, `outputs.tf`, this README, and native tests
under `tests/*.tftest.hcl` (plan + `mock_provider`).
