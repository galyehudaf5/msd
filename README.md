# msd

## What’s left to do (and how to demo)

With CI passing and images in GHCR (public), you’re ready to deploy via Argo CD and then present the full flow. Follow these steps:

1) Local cluster and Argo CD
- Create a local cluster (kind recommended) and install Argo CD.
- Create namespaces for apps used by the repo.

2) Apply GitOps manifests
- Apply the App-of-Apps and the ApplicationSet. They already point to this repo and GHCR image.

3) Open Argo CD UI and sync
- Log in to Argo CD, find `root-apps` → `web-app` and the two CNCF apps, ensure they sync and become Healthy.

4) Verify the app
- Port-forward the `web-app` service and hit both endpoints: `/` returns the ConfigMap-driven message, `/health` returns `{status:"ok"}`.

5) Optional: Release tagging
- Create a Git tag `vX.Y.Z` to produce a versioned image and auto-bump the chart `appVersion` in CI.

### PowerShell (Windows) quickstart

```powershell
# 1) kind cluster
kind create cluster --name dev

# 2) install Argo CD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 3) app namespaces (safe if they exist already)
kubectl create namespace web ; kubectl create namespace ingress-nginx ; kubectl create namespace argo-rollouts

# 4) apply GitOps manifests
kubectl apply -n argocd -f cd/apps/app-of-apps.yaml
kubectl apply -n argocd -f cd/applicationsets/cncf-apps.yaml

# 5) get Argo CD admin password and open UI
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' |
	% {[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($_))}; echo
kubectl -n argocd port-forward svc/argocd-server 8080:443
# browse to https://localhost:8080 and log in as admin

# 6) verify the app is running and test endpoints
kubectl -n web get deploy,svc,pods
kubectl -n web port-forward svc/web-app-web-app 8080:8080
# In another terminal:
curl http://localhost:8080/
curl http://localhost:8080/health
```

## Assignment mapping and design notes

- Git best practices
	- Main branch protected by PR validation (`.github/workflows/pr-validate.yml`).
	- Feature branches: run lint/tests/coverage without version bumping.
	- Clear commit messages; semantic tags `vX.Y.Z` drive releases.

- Dockerfile (multi-stage + cache)
	- `app/Dockerfile` uses a deps stage to cache `npm ci` and a minimal runtime stage.
	- Uses `--mount=type=cache` for npm cache.

- CI pipeline (DRY, secrets, versioning)
	- `.github/workflows/build-release.yml` builds with Buildx and pushes to GHCR.
	- Uses the default `GITHUB_TOKEN` with write:packages (no hardcoded secrets). If org blocks GHCR, use a PAT secret (`GHCR_TOKEN`).
	- Versioning: PR builds only test; merges to `main` push `main-<sha>`; tags `vX.Y.Z` push versioned images and auto-bump `charts/web-app/Chart.yaml` `appVersion`.

- Helm charts (library + app, ConfigMap)
	- `charts/lib-base` is a Helm library chart (DRY templates for Deployment/Service/ConfigMap).
	- `charts/web-app` consumes the library; `templates/deploy.yaml` includes the shared templates.
	- Config via ConfigMap (`config.webMessage`) and environment (`values*.yaml`).
	- `imagePullSecrets` supported (set `imagePullSecrets` in values if the image is private; you’re using public, so not needed).

- Argo CD (App-of-Apps + ApplicationSet)
	- App-of-Apps: `cd/apps/app-of-apps.yaml` points to `cd/apps/children` for the app definitions.
	- Child app: `cd/apps/children/web-app.yaml` deploys the chart from this repo with `values-dev.yaml` for dev env vars.
	- ApplicationSet: `cd/applicationsets/cncf-apps.yaml` deploys `ingress-nginx` and `argo-rollouts` using the List generator (simple, explicit). Alternatives include Git, Cluster, and Matrix generators depending on fleet/cluster topology.

## Demo talking points

- End-to-end flow: commit → PR checks (lint/tests) → merge → CI builds/pushes GHCR image → Argo CD syncs to cluster.
- Versioning: show image tags and chart `appVersion` bump on a tag release.
- DRY: Helm library chart reused by application chart; minimal duplication in templates.
- Secure CI: no plaintext secrets; least-privileged `GITHUB_TOKEN` with write:packages.
