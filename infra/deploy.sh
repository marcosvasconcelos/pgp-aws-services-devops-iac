#!/usr/bin/env bash
set -euo pipefail

# Usage: ./deploy.sh [init|plan|apply|destroy] [extra terraform args...]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
# TF_DIR specifies the Terraform working directory; override by setting the TF_DIR environment variable before running this script.
TF_DIR="${TF_DIR:-$SCRIPT_DIR}"
# Load environment variables from .env file
source "$ENV_FILE"

if ! command -v terraform >/dev/null 2>&1; then
    echo "terraform not found" >&2
    exit 1
fi

if [ -f "$ENV_FILE" ]; then
    set -a
    # shellcheck disable=SC1090
    . "$ENV_FILE"
    set +a
else
    echo ".env file not found at $ENV_FILE" >&2
    exit 1
fi

cmd="${1:-}"
shift || true

if [ -n "${TF_WORKSPACE:-}" ]; then
    if ! terraform -chdir="$TF_DIR" workspace list >/dev/null 2>&1; then
        terraform -chdir="$TF_DIR" init -input=false
    fi
    if ! terraform -chdir="$TF_DIR" workspace list | grep -q "^${TF_WORKSPACE}\$"; then
        terraform -chdir="$TF_DIR" workspace new "$TF_WORKSPACE"
    fi
    terraform -chdir="$TF_DIR" workspace select "$TF_WORKSPACE"
fi

case "$cmd" in
    init)
        terraform -chdir="$TF_DIR" init "$@"
        ;;
    plan)
        terraform -chdir="$TF_DIR" plan "$@"
        ;;
    apply)
        terraform -chdir="$TF_DIR" apply "$@"
        ;;
    destroy)
        terraform -chdir="$TF_DIR" destroy "$@"
        ;;
    *)
        echo "Usage: $0 {init|plan|apply|destroy} [extra args]" >&2
        exit 1
        ;;
esac