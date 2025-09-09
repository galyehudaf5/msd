<div align="center">

# msd

End-to-end Dev → CI → Image Build → GitOps Deploy (Argo CD) with Helm library reuse & automated versioning.

</div>

## Overview

This repository demonstrates a production-ready (but intentionally minimal) workflow:

1. Feature branch changes are validated (lint, unit tests, coverage, Docker build) via GitHub Actions.
2. Merges to `main` build and push an immutable image (`main-<git-sha>`) to GHCR and write back the new tag into `charts/web-app/values-dev.yaml`.
3. Argo CD (App-of-Apps pattern) auto-syncs the `web-app` Helm release using that updated image tag.
4. Optional semver tags (`vX.Y.Z`) produce versioned images and bump the Helm chart `appVersion` automatically.

This forms a clean, auditable chain: Git history = desired state; Argo CD reconciles cluster state to Git; all deployments trace back to commits and images.

## Key Components

| Area | Implementation |
|------|----------------|
| Language / App | Node.js Express server with `/` and `/health` |
| Tests | Jest (fast, single suit) |
| Linting | ESLint (Standard config, no tabs) |
| Container | Multi-stage Dockerfile with cached deps, smoke stage, HEALTHCHECK |
| Registry | GHCR (public) |
| Charts | Helm application chart + Helm library chart (`lib-base`) |
| GitOps | Argo CD App-of-Apps + ApplicationSet (ingress-nginx, argo-rollouts) |
| Config | ConfigMap-driven message (`config.webMessage`) + env vars |
| Versioning | Image: `main-<sha>` + optional semver tags; Chart `appVersion` bumped on tag release |
| Security | Only `GITHUB_TOKEN` (write:packages) needed; no embedded secrets |

## Repository Structure (Highlights)

```
app/                # Application code + Dockerfile + tests
charts/web-app      # Helm application chart (consumes library)
charts/web-app/charts/lib-base  # Helm library chart (Deployment/Service/ConfigMap templates)
cd/apps             # Argo CD App-of-Apps + child app manifests
cd/applicationsets  # ApplicationSet for CNCF dependencies
.github/workflows   # PR validation + build & release pipelines
```

## CI/CD Flow Details

### PR Validation (`.github/workflows/pr-validate.yml`)
Runs on pull requests to `main`:
- `npm ci`
- ESLint
- Jest (coverage)
- Docker build (ensures image will build, but no push)

### Build & Release (`.github/workflows/build-release.yml`)
Triggered on merges to `main` and on tags:
- Build multi-arch image (if configured) or default architecture
- Tag & push: `main-<sha>`, `<short-sha>`, `main-latest`
- Write back `charts/web-app/values-dev.yaml:image.tag`
- On tag `vX.Y.Z`: push `vX.Y.Z` image + bump chart `appVersion`

### GitOps Reconciliation
Argo CD watches the repo. When the workflow writes the new image tag to `values-dev.yaml`, Argo detects the commit and syncs the `web-app` deployment with the new immutable image.

## Helm Library Pattern
`lib-base` defines generic `_deployment.tpl`, `_service.tpl`, `_cm.tpl`. The application chart includes them to avoid duplication. This pattern scales cleanly if multiple services join later.

## Configuration Strategy
Values file drives:
- Image tag
- ConfigMap text (`config.webMessage`)
- Environment variables (`env.NODE_ENV`)

Runtime container imports the ConfigMap and env vars so a values change (message) triggers a rollout via template hash changes.

## Local Development
Minimal approach:
```powershell
cd app
npm ci
npm test
npm run lint
npm start  # (optional local run; not required for CI/CD demo)
```

## Running the GitOps Stack Locally (Kind + Argo CD)
See `DEMO_RUNBOOK.md` for a scripted, interview-friendly sequence. Quick summary:
1. Create Kind cluster & install Argo CD.
2. Apply App-of-Apps & ApplicationSet manifests.
3. Wait for sync → app Healthy.
4. Port-forward service → hit `/` & `/health`.
5. Make a tiny change → PR → merge → observe image tag update & rollout.

## Versioned Release (Optional Showpiece)
```powershell
git tag v0.1.0
git push origin v0.1.0
```
CI will:
1. Build & push `v0.1.0` image.
2. Bump `Chart.yaml` `appVersion` to `0.1.0` (commit back).
3. Argo will reconcile using same (already published) image unless you also switch environments to use the semver tag.

## Observability / Validation Tips
```powershell
# Current image in values (Git desired state)
Select-String -Path charts/web-app/values-dev.yaml -Pattern 'image:' -Context 0,2

# Deployment's live image
kubectl -n web get deploy web-app-web-app -o jsonpath="{.spec.template.spec.containers[0].image}"; echo

# Pod image (actual running)
kubectl -n web get pods -l app.kubernetes.io/name=web-app -o jsonpath="{.items[0].spec.containers[0].image}"; echo

# ConfigMap value
kubectl -n web get cm web-app-web-app-cfg -o jsonpath="{.data.WEB_MESSAGE}"; echo
```

## Talking Points (Interview)
- Immutable images + Git as source of truth.
- Separation of concerns: fast host tests vs minimal container smoke stage.
- DRY Helm library chart: scalable if adding more services.
- Argo CD App-of-Apps for composition + ApplicationSet for addon lifecycle.
- Safe automation: only workflow token; no manual kubectl after bootstrapping.
- Deterministic rollouts: hash changes on ConfigMap & image ensure redeploys.

## Next Possible Enhancements
- Add policy gating (Conftest / OPA) in PR workflow.
- Introduce progressive delivery (Argo Rollouts canary) using already-installed controller.
- Add SBOM + image signing (cosign) step.
- Add coverage threshold enforcement.

## License
Not specified; treat as internal demo unless a license is added.

---
For the full live demo script, open `DEMO_RUNBOOK.md`.
