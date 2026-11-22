#!/usr/bin/env bash
#
# Dev setup for software-factory-example-terraform.
# Installs the brake toolchain and activates the pre-commit git hook, so your
# local `git commit` runs the same checks CI does. Idempotent — safe to re-run.
#
# Package installs use the repo-local public-PyPI config (.config/pip/pip.conf),
# so a corporate pip proxy with an expiring token can't block them.
#
#   ./scripts/dev-setup.sh
set -euo pipefail

cd "$(dirname "$0")/.."
export PIP_CONFIG_FILE="$PWD/.config/pip/pip.conf"
export PATH="$HOME/.local/bin:$PATH"

has() { command -v "$1" >/dev/null 2>&1; }
missing=0

echo "▸ $(basename "$PWD") — pip index pinned to .config/pip/pip.conf (public PyPI)"

# ── System binaries the hooks shell out to ────────────────────────────────────
if has terraform; then echo "✓ terraform $(terraform version | head -1 | awk '{print $2}')"
else echo "✗ terraform missing — install >= 1.7: 'brew install terraform' or https://developer.hashicorp.com/terraform/install"; missing=1; fi

if has tflint; then echo "✓ tflint $(tflint --version | head -1)"
elif has brew; then echo "… installing tflint (brew)"; brew install tflint
else echo "✗ tflint missing — https://github.com/terraform-linters/tflint#installation"; missing=1; fi

# ── pipx (isolated Python CLIs) ───────────────────────────────────────────────
if ! has pipx; then
  echo "… installing pipx"
  if has brew; then brew install pipx; elif has pip3; then pip3 install --user pipx; else
    echo "✗ pipx missing and no brew/pip3 to install it"; missing=1; fi
  has pipx && pipx ensurepath >/dev/null 2>&1 || true
fi

# Checkov lags the newest Python; prefer 3.13 → 3.10.
pick_py() { for v in 3.13 3.12 3.11 3.10; do has "python$v" && { echo "python$v"; return; }; done; echo ""; }

# ── checkov ───────────────────────────────────────────────────────────────────
if has checkov; then echo "✓ checkov $(checkov --version 2>/dev/null | head -1)"
elif has pipx; then
  py="$(pick_py)"
  if [ -n "$py" ]; then echo "… installing checkov (pipx, $py)"; pipx install checkov --python "$py"
  else echo "✗ no python 3.10–3.13 for checkov — install one (e.g. 'brew install python@3.12')"; missing=1; fi
else missing=1; fi

# ── pre-commit ────────────────────────────────────────────────────────────────
if has pre-commit; then echo "✓ pre-commit $(pre-commit --version)"
elif has pipx; then echo "… installing pre-commit (pipx)"; pipx install pre-commit
elif has brew; then brew install pre-commit
else echo "✗ pre-commit missing — https://pre-commit.com/#install"; missing=1; fi

if [ "$missing" -ne 0 ]; then
  echo; echo "⚠ install the tools marked ✗ above, then re-run ./scripts/dev-setup.sh"; exit 1
fi

# ── Activate + verify ─────────────────────────────────────────────────────────
echo "▸ installing the git hook and building hook environments…"
pre-commit install
pre-commit install --install-hooks

echo "▸ running all hooks once to verify…"
pre-commit run --all-files || echo "⚠ some hooks reported issues above — fix them before committing"

echo "✓ done — 'git commit' in this repo now runs the brakes locally."
