#!/bin/bash
set -euo pipefail

CONFIG_PATH="${CONFIG_PATH:-.pre-commit-config.yaml}"
YQ_VERSION="v4.44.6"
CACHE_DIR="${HOME}/.cache/pre-commit-sast/bin"
YQ_BIN="${CACHE_DIR}/yq"

# ---------- auto-install yq ----------
ensure_yq() {
    if command -v yq >/dev/null 2>&1; then
        YQ_BIN="$(command -v yq)"
        return
    fi

    if [[ -x "$YQ_BIN" ]]; then
        return
    fi

    echo "yq not found in cache, downloading ${YQ_VERSION}…" >&2

    local os arch
    os="$(uname -s | tr '[:upper:]' '[:lower:]')"
    arch="$(uname -m)"

    case "$arch" in
        x86_64)  arch="amd64" ;;
        aarch64|arm64) arch="arm64" ;;
        *)
            echo "Unsupported architecture: $arch" >&2
            exit 1
            ;;
    esac

    mkdir -p "$CACHE_DIR"

    local url="https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_${os}_${arch}"
    if ! curl -fsSL "$url" -o "$YQ_BIN"; then
        echo "Failed to download yq from $url" >&2
        exit 1
    fi
    chmod +x "$YQ_BIN"
    echo "yq installed to $YQ_BIN" >&2
}

# ---------- validation ----------
validate() {
    if [[ ! -f "$CONFIG_PATH" ]]; then
        echo "$CONFIG_PATH not found" >&2
        exit 1
    fi

    ensure_yq

    local repo_count
    repo_count=$("$YQ_BIN" '.repos | length' "$CONFIG_PATH")

    local errors=()

    for ((i = 0; i < repo_count; i++)); do
        local repo rev
        repo=$("$YQ_BIN" ".repos[$i].repo" "$CONFIG_PATH")
        rev=$("$YQ_BIN" ".repos[$i].rev // \"\"" "$CONFIG_PATH")

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

