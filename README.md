# pre-commit-sast

Repo containing hooks for SAST tools. Check out `.pre-commit-config.yaml` for additional SAST tools.

## Trivy

Trivy configuration scanner with batch scanning for improved reliability.

### Features

- **Serial execution**: Prevents cache corruption from concurrent scans
- **Auto-detect ignore files**: Supports .trivyignore, .trivyignore.yaml, and trivy-policy.yaml
- **Clean and simple**: Minimal, focused implementation

### Usage

```yaml
- repo: https://github.com/jonny-wg2/pre-commit-sast
  rev: v0.0.3
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
