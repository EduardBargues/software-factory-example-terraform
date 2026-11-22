# Private modules (internal implementation)

Implementation modules composed by the public [`app`](../public/app/) module via
relative `source = "../../private/<name>"`. "Private" is **by convention** — a
public repo's files are all readable — but nothing outside this repo should
depend on them. The supported surface is `modules/public/app` only.

Planned internals (built when the app's first requirement lands):

- `lambda/` — the function, its IAM role, and alias.
- `dynamodb/` — table(s) the function reads/writes.
- `eventbridge/` — rules/targets wiring events to the function.

These are **empty on purpose** for now — see [`docs/factory/SPEC.md`](../../docs/factory/SPEC.md).

## Standalone (not composed by `app`)

- `github-oidc/` — **bootstrap**: the GitHub OIDC provider + the
  `terraform-testing` / `terraform-staging` / `terraform-production` IAM roles.
  Unlike the modules above, this is a **root module** (its own `provider`, applied
  by hand once with admin credentials — see its `README.md`), *not* a child module
  composed by `app`. **Don't reference it from `app`.**
