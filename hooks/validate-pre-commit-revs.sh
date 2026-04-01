#!/bin/bash
set -euo pipefail

CONFIG_PATH="${CONFIG_PATH:-.pre-commit-config.yaml}"

# ---------- check for yq ----------
if ! command -v yq >/dev/null 2>&1; then
    echo "yq is required but not installed." >&2
    exit 1
fi

# ---------- validation ----------
validate() {
    if [[ ! -f "$CONFIG_PATH" ]]; then
        echo "$CONFIG_PATH not found" >&2
        exit 1
    fi

    local repo_count
    repo_count=$(yq '.repos | length' "$CONFIG_PATH")

    local errors=()

    for ((i = 0; i < repo_count; i++)); do
        local repo rev
        repo=$(yq ".repos[$i].repo" "$CONFIG_PATH")
        rev=$(yq ".repos[$i].rev // \"\"" "$CONFIG_PATH")

        # 1-based index for human-readable messages
        local idx=$((i + 1))

        if [[ -z "$repo" || "$repo" == "null" ]]; then
            errors+=("repos[$idx] is missing a valid 'repo' value")
            continue
        fi

        if [[ "$repo" == "local" || "$repo" == "meta" ]]; then
            if [[ -n "$rev" && "$rev" != "null" ]]; then
                errors+=("repos[$idx] repo \"$repo\" must not define 'rev'")
            fi
            continue
        fi

        if ! [[ "$rev" =~ ^[0-9a-f]{40}$ ]]; then
            errors+=("repos[$idx] repo \"$repo\" must use a full 40-character SHA for 'rev' (got \"$rev\")")
        fi
    done

    if [[ ${#errors[@]} -gt 0 ]]; then
        echo "Invalid .pre-commit-config.yaml: remote repos must pin 'rev' to a full 40-character git SHA. Only 'local' and 'meta' repos are exempt." >&2
        for err in "${errors[@]}"; do
            echo "  - $err" >&2
        done
        exit 1
    fi
}

validate

