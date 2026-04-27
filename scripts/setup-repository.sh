#!/usr/bin/env bash

set -euo pipefail

REPO="${REPO:-vennet-consulting/autopack-website}"
VISIBILITY="${VISIBILITY:-public}"
REMOTE_URL="https://github.com/${REPO}.git"

if [[ ! -d .git ]]; then
  git init -b main >/dev/null
fi

if ! gh repo view "${REPO}" >/dev/null 2>&1; then
  gh repo create "${REPO}" \
    --"${VISIBILITY}" \
    --description "AutoPack marketing site and Azure Static Web App deployment infrastructure." \
    --disable-wiki
fi

if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "${REMOTE_URL}"
else
  git remote add origin "${REMOTE_URL}"
fi

./scripts/bootstrap-tfstate.sh
REPO="${REPO}" ./scripts/bootstrap-oidc.sh
REPO="${REPO}" ./scripts/configure-github-repo.sh

cat <<EOF

Repository bootstrap complete.

Remote:
  origin -> ${REMOTE_URL}

Next steps:
  1. Review the generated files.
  2. Commit and push the repository contents.
  3. Run the Infrastructure CI/CD workflow for dev, then prod.
  4. Run the App CI/CD workflow for dev, then prod.

EOF
