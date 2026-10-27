# site-service

AegisOps target service. `GET /health` and `GET /version` are required. CI registers artifacts in the `site-service` project and requests a Staging deployment.

`demo/vulnerable` is a demo branch and is never merged. It contains a fake AWS example key, a SQL string concatenation endpoint, an MD5 hash, and an old runtime image so Gitleaks, Semgrep, and Trivy can produce findings. See [the security-denial runbook](docs/security-denial-demo.md) before running its opt-in CI path. Never deploy the vulnerable image.
