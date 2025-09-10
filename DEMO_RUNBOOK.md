# CI/CD + GitOps Live Demo Runbook

Purpose: Crisp, time-boxed walkthrough (~8–12 min) proving the full path: Code → PR Checks → Merge → Image Build → GitOps Deploy (Argo CD) → Verification → Optional Tag Release.

## 0. Prep (Before Interview)
- Ensure GHCR images from `main` exist (already produced by pipeline).
- Have a clean local clone on `main`.
- Kind & kubectl installed; Docker running.
- (Optional) Pre-pull latest base Node image to reduce build latency.

## 1. Bootstrap Cluster & Argo CD (2–3 min)
```powershell
kind create cluster --name demo
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=available -n argocd deploy/argocd-repo-server --timeout=180s
```

Create app namespaces (idempotent):
```powershell
kubectl create namespace web ; kubectl create namespace ingress-nginx ; kubectl create namespace argo-rollouts
```

Apply GitOps manifests:
```powershell
kubectl apply -n argocd -f cd/apps/app-of-apps.yaml
kubectl apply -n argocd -f cd/applicationsets/cncf-apps.yaml
```

Login (terminal password retrieval):
```powershell
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | % { [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($_)) }; echo
kubectl -n argocd port-forward svc/argocd-server 8080:443
# Browser: https://localhost:8080  (user: admin)
```

Narrate: “Argo CD App-of-Apps creates the core application; ApplicationSet installs shared CNCF addons (ingress-nginx, argo-rollouts).”

## 2. Observe Sync (1 min)
In UI: root → child `web-app` → ensure Healthy/Synced.
Optionally show CRs:
```powershell
kubectl -n web get deploy,svc,pods
```

## 3. Verify Running App (1 min)
```powershell
kubectl -n web port-forward svc/web-app-web-app 8080:80 --address 127.0.0.1
```
New terminal:
```powershell
curl http://127.0.0.1:8080/health
curl http://127.0.0.1:8080/
```
Expect JSON with ConfigMap-driven message.

## 4. Make a Tiny Change (2–3 min)
In repo:
```powershell
git checkout -b feat/demo-text
# Edit app/src/server.js (adjust a harmless log or comment)
# Example: add console.log('Interview demo change') inside startup block.

npm run lint
npm test
git add app/src/server.js
git commit -m "chore: interview demo tiny change"
git push -u origin feat/demo-text
```

Open PR in GitHub. Show PR checks: lint/tests/coverage + docker build.
Explain: “We do NOT push images on PRs; only validate.”

## 5. Merge & Trigger Release (2 min)
Merge PR → watch Actions `build-release` workflow:
- Builds image `main-<sha>`
- Writes `image.tag` back to `charts/web-app/values-dev.yaml`
- Commit appears on `main` (often with `[skip ci]` if logic used)

Show diff of updated values file:
```powershell
git fetch origin main
git checkout main
git pull --ff-only
Select-String -Path charts/web-app/values-dev.yaml -Pattern 'image:' -Context 0,2
```

## 6. Argo CD Auto-Sync (1 min)
In Argo UI, show rollout of new ReplicaSet / Pod.
Confirm live image:
```powershell
kubectl -n web get deploy web-app-web-app -o jsonpath="{.spec.template.spec.containers[0].image}"; echo
kubectl -n web get pods -l app.kubernetes.io/name=web-app -o jsonpath="{.items[0].spec.containers[0].image}"; echo
```
Port-forward again (if restarted) and hit `/` to prove availability during change.

## 7. (Optional) Show Versioned Release (2–3 min)

$ver = 'v0.8.0'
git checkout main; git pull --ff-only
git tag -a $ver -m "Release $ver"
git push origin $ver

Explain: “A tag triggers two workflows: Build & Release builds/pushes the image tag (vX.Y.Z + short SHA), and Tag Release opens a chore/chart-bump-vX.Y.Z branch updating Helm Chart.yaml appVersion + version metadata.”
After workflows:
```powershell
Select-String -Path charts/web-app/Chart.yaml -Pattern 'appVersion'
```
Mention: environment promotion could pin on semver tags instead of `main-<sha>`.

## 8. Wrap Talking Points
- Immutable tag written into Git → GitOps reconciles.
- Library Helm chart keeps deployment/service/configmap DRY.
- Fast feedback (host lint/tests) vs container smoke.
- Minimal secret surface (only GitHub token for packages).
- Easy extension: add more services by reusing `lib-base`.

## Troubleshooting Quickies
| Symptom | Fix |
|---------|-----|
| Argo app OutOfSync | Check last commit updated image tag; refresh app in UI |
| Pod CrashLoopBackOff | Inspect logs: `kubectl -n web logs <pod>` |
| No new rollout after merge | Ensure image tag changed in values; confirm workflow write-back commit |
| PR checks slow | Confirm dependency caching and minimal test surface |

## Time Budget Suggestion
| Segment | Target |
|---------|--------|
| Cluster + Argo bootstrap | 3 min |
| Sync + verify app | 2 min |
| Change + PR + merge | 4 min |
| Auto-sync & verification | 2 min |
| Optional tag release | 2 min |

Total: 11–13 min (skip tag to fit 10 min).

Good luck on the interview!
