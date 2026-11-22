# Code Standards

The **fuzzy** conventions the `agent:review` brake enforces — the ones a deterministic check can't express. Deterministic rules live in the brakes (`terraform fmt`, `terraform validate`, `tflint`, `Checkov`, `gitleaks`, native `terraform test`); this file is only for what a careful human reviewer would catch but a linter can't.

**This file starts empty on purpose.** Standards are *earned*, not guessed: each one should come from a real miss surfaced by `/retro`, not from speculation about code that doesn't exist yet. An invented rule is sediment before it is ever useful.

**How it grows**

- When a run gets something wrong that the brakes didn't catch, run `/retro`. For each finding, decide:
  - **Can it be a deterministic check?** (a `tflint` rule, a Checkov policy, a native `terraform test` assertion) → build the check. It guards the repo every time, where the review agent is probabilistic and may miss it again. *Prefer this.*
  - **Is it genuinely fuzzy** — un-mechanizable judgment? → add a short rule below.
  - **Is it a process rule** (about workflow, not about the diff)? → it belongs in the spec or config, not here.
- Keep it lean. Prune no-ops and duplicates whenever the file grows.
- Don't duplicate the other steering files: vocabulary lives in [`GLOSSARY.md`](GLOSSARY.md) (shared terms in the home repo), design intent in [`docs/factory/SPEC.md`](docs/factory/SPEC.md). The review run reads all three.
- The **review** run enforces these standards; the implementer only writes a first draft. No run edits this file — it is a guardrail, curated by a human or `/retro`.

## Standards

_(none yet — the first one will come from a `/retro` finding)_
