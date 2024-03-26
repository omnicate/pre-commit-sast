# pre-commit-sast

Repo containing hooks for SAST tools. Check out `.pre-commit-config.yaml` for additional SAST tools.

## Trivy

Trivy conf

`.pre-commit-config.yaml`

```yaml
- repo: https://github.com/jonny-wg2/pre-commit-sast
  rev: v0.0.1
  hooks:
    - id: trivyconfig
      args:
        - "--args=--severity HIGH,CRITICAL"
        - "--args=--ignorefile .trivyignore"
```
