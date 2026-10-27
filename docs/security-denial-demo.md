# Reproduce a Staging security denial (demo/vulnerable only)

This branch is deliberately insecure and must not be merged into `main`, tagged for
release, or deployed to any environment. The demonstration is the **policy denial**, not
a deployment. A previous run reported 11 Critical findings and was Denied; new scans
must be examined independently. No finding count or outcome is guaranteed.

## Before authorizing an external push

- Obtain explicit authorization for one commit and push to the existing remote
  `demo/vulnerable` branch, its GHCR image publication, artifact and three real SARIF
  registrations, and a **Staging-only** deployment request (expected to be denied).
  Do not authorize a Production request or any exception to the Critical-finding rule.
- Confirm the remote branch head has not moved; review the diff and preserve the
  vulnerable fixture (`Dockerfile` old runtime, `src/Service/Program.cs` insecure
  examples, `src/Service/appsettings.Demo.json` example key). The example key is not
  a live secret. Do not push a branch that contains unrelated local fixture changes.
- Inspect the effective site-service Staging policies and target. If the Staging branch
  allowlist blocks this run, add the **exact `demo/vulnerable` branch**, not a wildcard;
  retain existing permitted branches. Any adjustment requires separate operator approval
  and should be reverted afterward; do not weaken required scans, tests, or the
  baseline `Critical > 0` deny rule, and do not change Production policy. Without
  an approved Staging branch rule, a denial could be for the wrong reason.
- Check the Staging `currentArtifactId`, Production `currentArtifactId`, and running
  container/image before the run. Stop if the target or policy differs from what the
  operator approved.

## Opt-in and evidence

Only a push to the exact `demo/vulnerable` ref with a standalone
`[security-denial:staging]` line in its **head commit message** can reach image
publication, scanners and registration. No `workflow_dispatch` trigger is available.
Other demo refs cannot register through this path; PRs cannot publish or register.
All registration requests use `deploy-to: Staging` (including main/tags); this branch
cannot select Production via an input. Run `dotnet run --project
tests/Service.Tests/Service.Tests.csproj --no-launch-profile` and
`bash tests/ci-contract.sh` locally before requesting the push. CI reruns use unique
run/attempt image versions and real test totals; scanner errors fail CI rather than
manufacturing clean SARIF. Gitleaks, Semgrep and Trivy must each report from the run.

After an authorized push, record the GitHub run ID/attempt, image digest, artifact ID,
test summary, SARIF reports, scan statuses and policy evaluation. Confirm completed
scans contain actual findings and the evaluation explicitly says `Deny` due to
Critical findings exceeding zero. A rejected branch, missing scan, failed test or
failed scanner is **not** proof of a security-finding denial. The report action
requests Staging after registering the scans; the policy engine must reject that
request before a worker can deploy. Verify no Staging deployment succeeded or ran,
and both Staging and Production artifact IDs and container IDs remain unchanged.
If the decision is `Allow`, `RequireApproval`, or ambiguous, stop and investigate
immediately; do not approve or deploy the vulnerable image, retry to evade findings,
or disable any policy. Preserve all evidence and leave running services untouched.
