# pre-commit-sast

Repo containing hooks for SAST tools.

## Trivy

Trivy conf

`.pre-commit-config.yaml`

```yaml
- repo: https://github.com/jonny-wg2/pre-commit-sast.git
  hooks:
    - id: trivyconfig
      args:
        - "--args=--severity HIGH,CRITICAL"
        - "--args=--ignorefile .trivyignore"
```
