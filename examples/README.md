# Examples

Each subdirectory here instantiates the public [`app`](../modules/public/app/)
module for testing. Examples are the **only** Terraform configs this repo ever
applies — and only **ephemerally**, during the on-demand `run-e2e` job (apply →
assert → destroy) in the sandbox account. They are never a persistent
environment.

Native tests (`terraform test` with `mock_provider`) can also point at an example
for credential-free, plan-level coverage in the per-PR brakes.

**Empty on purpose** for now — the first example lands with the first module.
