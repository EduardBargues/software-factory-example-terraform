# Private modules (internal implementation)

Implementation modules composed by the public [`app`](../public/app/) module via
relative `source = "../../private/<name>"`. "Private" is **by convention** — a
public repo's files are all readable — but nothing outside this repo should
depend on them. The supported surface is `modules/public/app` only.

Planned internals (built when the app's first requirement lands):

- `lambda/` — the function, its IAM role, and alias.
- `dynamodb/` — table(s) the function reads/writes.
- `eventbridge/` — rules/targets wiring events to the function.

**Empty on purpose** for now — see [`docs/factory/SPEC.md`](../../docs/factory/SPEC.md).
