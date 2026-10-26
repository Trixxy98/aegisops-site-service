# site-service

AegisOps target service. `GET /health` and `GET /version` are required. CI registers artifacts in the `site-service` project and requests a Staging deployment.

## CI → Staging prerequisites (main branch)

1. In this repository's GitHub Settings → Actions, permit the external composite action
   `Trixxy98/AegisOps---DevSecOps-AI-Control-Plane/.github/actions/aegisops-report@dev`.
   Publish the matching control-plane `dev` branch containing the report validation before
   running CI; preferably pin a reviewed commit SHA instead of `@dev` afterward.
2. Register an **online Linux self-hosted runner** for this target repository (`self-hosted`
   label), with bash, jq, curl and outbound access to GitHub for checkout/artifact downloads.
   The runner must be able to resolve and reach the AegisOps API directly: from the runner,
   `curl -fS https://<api-host>/health/ready` must succeed. `localhost` points to the runner,
   not the GitHub-hosted build job. Use a private network/VPN and HTTPS for remote access.
3. In this target repository's Settings → Secrets and variables → Actions, set repository
   **variable** `AEGISOPS_URL` to the API base URL (no `/api/v1`, e.g. `https://<api-host>`)
   and repository **secret** `AEGISOPS_API_KEY` to a fresh key for the existing `site-service`
   project. An admin/team owner creates it from AegisOps under the project's API Keys page,
   with `artifacts:write`, `scans:write`, `deployments:request` scopes and a suitable expiry.
   Copy the one-time plaintext into GitHub, never into the repo, runner logs, or shell history.
   PRs from forks do not receive these secrets and do not execute the register job.
4. Confirm the Staging environment and worker are configured in AegisOps, the worker can
   pull the published GHCR image, has Docker access and host-reachable target health checks.
   The Development Compose noop executor **does not** deploy a Staging container. Do not
   point the worker at the main database for a trial run.

Run `bash tests/ci-contract.sh` and `dotnet run --project tests/Service.Tests/Service.Tests.csproj --no-launch-profile`
locally to check tests and report guards. After reviewing/publishing this workflow, push a
new commit to `main`. The build publishes the image,
scanners upload real SARIF, and the runner registers the artifact/scans and requests deployment.
Check the AegisOps deployment timeline and target `/version` rather than treating a green
request job as proof that worker deployment succeeded.

**Manual Staging retry:** do not rerun CI to redeploy an existing version. In AegisOps,
select the already registered artifact (verify its image digest and completed scans), then
request a new Staging deployment of that artifact. This does not rebuild or push its GHCR
tag. If a fresh build is required, push a new commit to `main`; every CI run/attempt gets
its own `-run.<run-id>.<attempt>` image tag and artifact version, including version tags.
Do not manually retag an existing registered artifact.
