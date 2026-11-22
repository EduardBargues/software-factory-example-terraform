# Issue tracker: GitHub

Issues and specs for this repo live as GitHub issues. Use the `gh` CLI for all operations.

## Conventions

- **Create an issue**: `gh issue create --title "..." --body "..."`. Use a heredoc for multi-line bodies.
- **Read an issue**: `gh issue view <number> --json number,title,body,labels,comments`.
- **List issues**: `gh issue list --state open --json number,title,body,labels,comments --jq '[.[] | {number, title, body, labels: [.labels[].name], comments: [.comments[].body]}]'` with appropriate `--label` and `--state` filters.
- **Blocking**: GitHub's native issue dependencies. Add an edge with `gh issue edit <child> --add-blocked-by <blocker>` (`gh` 2.94+). A ticket is unblocked when every blocker is closed.
- **Comment on an issue**: `gh issue comment <number> --body "..."`
- **Apply / remove labels**: `gh issue edit <number> --add-label "..."` / `--remove-label "..."`
- **Close**: post the explanation with `gh issue comment <number> --body "..."`, then `gh issue close <number>`.

Infer the repo from `git remote -v`; `gh` does this automatically when run inside a clone. This repo is `EduardBargues/software-factory-example-terraform`.

File issues only into this repo. In a fork, `gh` can default to the upstream parent, so before the first `gh issue create` of a session, check the target with `gh repo view --json nameWithOwner` and confirm it is this repo.

## Factory labels

- `agent:explore` — start a read-only explore run on an issue.
- `agent:implement` — build the ticket and open a draft PR.
- `agent:review` — review a PR, fix what's safe, mark ready.
- `run-e2e` — (PR only) run the on-demand real-apply Terratest e2e in the testing environment.
- `agent:rebase` — (PR only) rebase this one PR onto its base now.

## When a skill says "publish to the issue tracker"

Create a GitHub issue. When a skill says "fetch the relevant ticket", read it as in **Read an issue** above.
