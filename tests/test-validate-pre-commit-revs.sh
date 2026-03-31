#!/bin/bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="${SCRIPT_DIR}/hooks/validate-pre-commit-revs.sh"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

PASS=0
FAIL=0

run_test() {
    local name="$1"
    local config_file="$2"
    local expected_exit="$3"
    local expected_stderr="${4:-}"

    local actual_exit=0
    local stderr_output
    stderr_output=$(CONFIG_PATH="$config_file" bash "$HOOK" 2>&1) || actual_exit=$?

    local ok=true

    if [[ "$actual_exit" -ne "$expected_exit" ]]; then
        ok=false
    fi

    if [[ -n "$expected_stderr" ]] && ! echo "$stderr_output" | grep -qF "$expected_stderr"; then
        ok=false
    fi

    if $ok; then
        echo "  ✅ PASS: $name"
        ((PASS++))
    else
        echo "  ❌ FAIL: $name"
        echo "       expected exit=$expected_exit, got exit=$actual_exit"
        if [[ -n "$expected_stderr" ]]; then
            echo "       expected stderr to contain: $expected_stderr"
            echo "       actual stderr: $stderr_output"
        fi
        ((FAIL++))
    fi
}

# -------------------------------------------------------
echo "=== validate-pre-commit-revs tests ==="
echo ""

# Test 1: valid remote repo with 40-char SHA
cat > "$TMPDIR/t1.yaml" << 'EOF'
repos:
  - repo: https://github.com/example/repo
    rev: bf2ab7d452c8557b5be44dabe25d09946a785d4e
    hooks:
      - id: my-hook
EOF
run_test "valid 40-char SHA passes" "$TMPDIR/t1.yaml" 0

# Test 2: remote repo with tag (should fail)
cat > "$TMPDIR/t2.yaml" << 'EOF'
repos:
  - repo: https://github.com/example/repo
    rev: v1.2.3
EOF
run_test "tag rev is rejected" "$TMPDIR/t2.yaml" 1 "must use a full 40-character SHA"

# Test 3: remote repo with short SHA (should fail)
cat > "$TMPDIR/t3.yaml" << 'EOF'
repos:
  - repo: https://github.com/example/repo
    rev: abc1234
EOF
run_test "short SHA is rejected" "$TMPDIR/t3.yaml" 1 "must use a full 40-character SHA"

# Test 4: local repo without rev (should pass)
cat > "$TMPDIR/t4.yaml" << 'EOF'
repos:
  - repo: local
    hooks:
      - id: local-hook
EOF
run_test "local repo without rev passes" "$TMPDIR/t4.yaml" 0

# Test 5: meta repo without rev (should pass)
cat > "$TMPDIR/t5.yaml" << 'EOF'
repos:
  - repo: meta
    hooks:
      - id: check-hooks-apply
EOF
run_test "meta repo without rev passes" "$TMPDIR/t5.yaml" 0

# Test 6: local repo WITH rev (should fail)
cat > "$TMPDIR/t6.yaml" << 'EOF'
repos:
  - repo: local
    rev: abc123
    hooks:
      - id: my-hook
EOF
run_test "local repo with rev is rejected" "$TMPDIR/t6.yaml" 1 "must not define 'rev'"

# Test 7: meta repo WITH rev (should fail)
cat > "$TMPDIR/t7.yaml" << 'EOF'
repos:
  - repo: meta
    rev: abc123
EOF
run_test "meta repo with rev is rejected" "$TMPDIR/t7.yaml" 1 "must not define 'rev'"

# Test 8: missing repo field (should fail)
cat > "$TMPDIR/t8.yaml" << 'EOF'
repos:
  - hooks:
      - id: orphan
EOF
run_test "missing repo field is rejected" "$TMPDIR/t8.yaml" 1 "missing a valid 'repo' value"

# Test 9: missing config file (should fail)
run_test "missing config file is rejected" "$TMPDIR/nonexistent.yaml" 1 "not found"

# Test 10: mixed valid and invalid (should fail)
cat > "$TMPDIR/t10.yaml" << 'EOF'
repos:
  - repo: https://github.com/good/repo
    rev: bf2ab7d452c8557b5be44dabe25d09946a785d4e
  - repo: https://github.com/bad/repo
    rev: v2.0.0
  - repo: local
    hooks:
      - id: local-hook
EOF
run_test "mixed valid/invalid reports error" "$TMPDIR/t10.yaml" 1 "must use a full 40-character SHA"

# Test 11: multiple remote repos all valid (should pass)
cat > "$TMPDIR/t11.yaml" << 'EOF'
repos:
  - repo: https://github.com/example/repo1
    rev: bf2ab7d452c8557b5be44dabe25d09946a785d4e
  - repo: https://github.com/example/repo2
    rev: 8b4b26313328afdbbb30470cc09d3b7de643e7e6
  - repo: local
    hooks:
      - id: local-hook
EOF
run_test "multiple valid repos pass" "$TMPDIR/t11.yaml" 0

# Test 12: remote repo with empty rev (should fail)
cat > "$TMPDIR/t12.yaml" << 'EOF'
repos:
  - repo: https://github.com/example/repo
    rev: ""
EOF
run_test "empty rev is rejected" "$TMPDIR/t12.yaml" 1 "must use a full 40-character SHA"

# -------------------------------------------------------
echo ""
echo "Results: $PASS passed, $FAIL failed"
if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi

