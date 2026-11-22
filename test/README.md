# Terratest end-to-end tests

Go-based real-apply tests (Gruntwork [Terratest](https://terratest.gruntwork.io/)).
Each test applies an `examples/` instance against the **sandbox** AWS account,
asserts real behavior via the AWS SDK, and **destroys** it — whether the test
passes or fails.

These run **on demand only**, via the `run-e2e` PR label (`.github/workflows/run-e2e.yml`),
never on every PR and never on a schedule. The per-PR brakes stay credential-free
(native `terraform test` + mocks); this is the layer that touches a real cloud.

## Status

No cases yet (the repo is module-empty). Add the first one with the first module.

## Adding a case

1. Add the deps once: `go get github.com/gruntwork-io/terratest/modules/terraform` (and the AWS SDK for assertions). Requires Go >= 1.26 for Terratest v2.
2. Create `<name>_test.go`:

```go
package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestAppLambdaWebapp(t *testing.T) {
	opts := &terraform.Options{TerraformDir: "../examples/app-basic"}
	defer terraform.Destroy(t, opts)      // always tears down
	terraform.InitAndApply(t, opts)
	url := terraform.Output(t, opts, "function_url")
	// e.g. HTTP GET the URL and assert a 200 — the "ping the deployed webapp" check.
	_ = url
}
```

3. Commit through the brakes. Trigger it on a PR by adding the `run-e2e` label.

Keep each test's resources uniquely named (random suffix) so concurrent runs don't
collide, and rely on the sandbox reaper to sweep anything a failed `destroy` leaks
(see `docs/factory/RUNBOOK.md`).
