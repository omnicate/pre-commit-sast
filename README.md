# pre-commit-sast

Repo containing hooks for SAST tools. Check out `.pre-commit-config.yaml` for additional SAST tools.

## Validate pre-commit revs

Require remote pre-commit repos to pin `rev` to a full 40-character git
SHA. This prevents floating tags and short SHAs in `.pre-commit-config.yaml`.

### Rules

- Remote repos must use a 40-character lowercase git SHA in `rev`
- `repo: local` and `repo: meta` are exempt and must not define `rev`

### Usage

```yaml
- repo: https://github.com/jonny-wg2/pre-commit-sast
  rev: bf2ab7d452c8557b5be44dabe25d09946a785d4e
  hooks:
    - id: validate-pre-commit-revs
```

This hook runs the shared Go implementation from this repository.
It is packaged as a `golang` pre-commit hook.

## Trivy

Trivy configuration scanner with batch scanning for improved reliability.

### Features

- **Serial execution**: Prevents cache corruption from concurrent scans
- **Auto-detect ignore files**: Supports .trivyignore, .trivyignore.yaml, and trivy-policy.yaml
- **Clean and simple**: Minimal, focused implementation

### Usage

```yaml
- repo: https://github.com/jonny-wg2/pre-commit-sast
  rev: d2a8229042fbfb25c79514a075d8f1b029c157d1
  hooks:
    - id: trivyconfig
      args:
        - "--args=--severity HIGH,CRITICAL"
```

### Ignore Files (Optional)

Create any of these files in your repo root - they're auto-detected:

- **`.trivyignore`** - Simple list of IDs to ignore
- **`.trivyignore.yaml`** - Structured ignores with paths and reasons

**Auto-detection**: The hook automatically finds these files unless you specify `--ignorefile` manually in your pre-commit config.
