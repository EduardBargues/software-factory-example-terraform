# Bootstrap: GitHub OIDC roles

Creates the **GitHub OIDC provider** and **one tag-scoped IAM role per environment**
— `terraform-testing`, `terraform-staging`, `terraform-production` — so GitHub
Actions can assume them **keylessly** (no long-lived AWS keys). Because you have a
single AWS account, the boundary between environments is the **`environment`
resource tag** (ABAC): the `terraform-testing` role can only touch resources tagged
`environment=testing`, and likewise for `staging` and `production`.

The three map to the deploy flow:

- **testing** — the terraform module library's own ephemeral `run-e2e`.
- **staging** — the app deploys here on a **PR** (on-demand) *and* just after
  **merging to main** (before production).
- **production** — the app deploys here only **after merging to main**.

This is **bootstrap** — persistent IAM, applied **once, by hand, with admin
credentials**. It is deliberately outside the module-library contract (the
library's CI never applies persistent infra; see `docs/adr/0001`).

## Prerequisites: admin credentials (one-time)

Creating IAM providers/roles/policies needs admin-level access **once**. You don't
need a special "administrator role" if you already have admin on the account —
pick whichever you have:

- **Account owner / existing admin** — if you created the account, use it directly.
- **IAM Identity Center (SSO)** *(recommended)* — assign yourself the
  `AdministratorAccess` permission set, then `aws sso login`. No static keys.
- **IAM user with `AdministratorAccess`** — create one, make an access key,
  `aws configure`. Works, but it's a long-lived key — delete or lock it down
  after bootstrap.

Verify you're on the intended account before applying:

```bash
aws sts get-caller-identity
```

After bootstrap, day-to-day deploys/tests use the OIDC roles below — **admin is
only needed for this one-time step** (and future IAM changes).

## Apply

```bash
cd modules/private/github-oidc
terraform init
# If a GitHub OIDC provider already exists in the account:
#   terraform apply -var=create_oidc_provider=false
terraform apply
terraform output role_arns
```

## Wire the outputs to the factory

- **testing** → the terraform repo's `AWS_TESTING_ROLE_ARN` secret (used by
  `run-e2e`). The wizard `scripts/setup-terraform-secrets.sh` can read it straight
  from `terraform output`, or:
  ```bash
  gh secret set AWS_TESTING_ROLE_ARN --repo EduardBargues/software-factory-example-terraform \
    --body "$(terraform -chdir=modules/private/github-oidc output -json role_arns | jq -r .testing)"
  ```
- **staging** / **production** → the **app repo** (`software-factory-example-python`),
  for its deploy tier. Wire these when that deploy lands (the workflow will define
  the exact secret names, e.g. `AWS_STAGING_ROLE_ARN` / `AWS_PRODUCTION_ROLE_ARN`).

```bash
terraform -chdir=modules/private/github-oidc output -json role_arns   # all three ARNs
```

## The ABAC boundary — read this

The tag is the ONLY thing separating environments in one account, so:

- **Every resource a run creates must be tagged `environment = <env>`.** The
  create permission is conditioned on `aws:RequestTag/environment`, so an untagged
  `terraform apply` will be **denied**. In your modules, set
  `tags = { environment = var.environment }` on everything (or use the AWS
  provider's `default_tags`).
- Name each Lambda **execution role** with the env prefix (`testing-...`,
  `production-...`) — the IAM statement is scoped to `role/<env>-*`.
- The starter policy covers `lambda`, `dynamodb`, `events`, `logs`, and IAM for
  the function role. **Validate and extend** it per the services your modules
  actually use — ABAC coverage differs by service/action.

## Trust mapping (defaults, edit in `variables.tf`)

- **testing** — trusted by both repos (either can run e2e), subject `…:*`.
- **production** — trusted only by the app repo's **main** branch
  (`…:ref:refs/heads/main`).

Subjects use GitHub's immutable-subject format
(`repo:<owner>@<owner_id>/<repo>@<repo_id>:…`), which both repos already emit.
