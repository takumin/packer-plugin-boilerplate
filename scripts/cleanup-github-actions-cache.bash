#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$(dirname "${SCRIPT_DIR}/../..")" && pwd)"

date '+%s' > "${PROJECT_DIR}/.github/dependency/actions-cache-version"
