#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$(dirname "${SCRIPT_DIR}/../..")" && pwd)"

cd "${PROJECT_DIR}"

ORIGIN_OWNER="takumin"
ORIGIN_AUTHOR_NAME="Takumi Takahashi"
ORIGIN_REPOSITORY="packer-plugin-boilerplate"
ORIGIN_DESCRIPTION="Boilerplate Packer Plugin"

GITHUB_NAME_WITH_OWNER="$(gh repo view --json nameWithOwner --jq '.nameWithOwner')"

GITHUB_OWNER="${GITHUB_NAME_WITH_OWNER%/*}"
GITHUB_REPOSITORY="${GITHUB_NAME_WITH_OWNER##*/}"
GITHUB_DESCRIPTION="$(gh repo view --json description --jq '.description')"
GITHUB_DESCRIPTION="${GITHUB_DESCRIPTION/\&/\\&}"

GITHUB_AUTHOR_NAME="$(gh api "users/${GITHUB_OWNER}" --jq '.name')"
[[ -z "${GITHUB_AUTHOR_NAME}" ]] && GITHUB_AUTHOR_NAME="${GITHUB_OWNER}"

ORIGIN_URL="github.com/${ORIGIN_OWNER}/${ORIGIN_REPOSITORY}"
GITHUB_URL="github.com/${GITHUB_OWNER}/${GITHUB_REPOSITORY}"

go mod edit -module "${GITHUB_URL}"
go-imports-rename -s "${ORIGIN_URL} => ${GITHUB_URL}"

gofmt -w .

sed -i -E "s@${ORIGIN_URL}@${GITHUB_URL}@" README.md
sed -i -E "s@${ORIGIN_OWNER}@${GITHUB_OWNER}@" README.md
sed -i -E "s@${ORIGIN_AUTHOR_NAME}@${GITHUB_AUTHOR_NAME}@" README.md
sed -i -E "s@${ORIGIN_REPOSITORY}@${GITHUB_REPOSITORY}@" README.md
sed -i -E "s@${ORIGIN_DESCRIPTION}@${GITHUB_DESCRIPTION}@" README.md

sed -i -E "s@${ORIGIN_URL}@${GITHUB_URL}@" CODE_OF_CONDUCT.md

sed -i -E "s@\[yyyy\]@$(date "+%Y")@" LICENSE
sed -i -E "s@\[name of copyright owner\]@${GITHUB_AUTHOR_NAME}@" LICENSE
