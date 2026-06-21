# 🐙 `argo-terraform` — Install Argo CD & Register the Application

This Terraform module installs **Argo CD** into the AKS cluster and registers the **`supermario-app`** Application so GitOps deployment can begin. This is **Stage 2** of the deployment and assumes the cluster from [`aks-terraform`](../aks-terraform/README.md) already exists.

> ⬅️ Back to the [main project README](../README.md)

---

## What this module does

| Resource | Purpose |
|----------|---------|
| `kubernetes_namespace_v1.argocd` | Creates the `argocd` namespace |
| `null_resource.install_argocd` | `kubectl apply` the official Argo CD install manifest (server-side) |
| `null_resource.apply_service_patch` | Patches the Argo CD server Service (see `argocd-service-patch.yaml`) to expose the UI |

The Argo CD **Application** is defined declaratively in [`supermario-application.yaml`](supermario-application.yaml):

```yaml
spec:
  source:
    repoURL: https://github.com/Ike-DevCloudIQ/devsecops-aks-pipeline.git
    targetRevision: main
    path: k8s            # Argo CD watches this folder
  destination:
    namespace: default
  syncPolicy:
    automated:
      prune: false
      selfHeal: false
```

> 🔑 Argo CD continuously watches the **`k8s/`** folder on the `main` branch. Any commit there is automatically reconciled into the cluster.

---

## Prerequisites

- The AKS cluster from [`aks-terraform`](../aks-terraform/README.md) is running.
- `kubectl` is pointed at that cluster (`kubectl get nodes` works).
- The `kubernetes` provider reads your kubeconfig from `~/.kube/config` (see [`provider.tf`](provider.tf)).

---

## Step-by-step

### 1. Initialize Terraform

```bash
cd argo-terraform
terraform init
```

### 2. Apply — installs Argo CD

```bash
terraform apply -auto-approve
```

Confirm the Argo CD components are running:

```bash
kubectl get pods -n argocd
```

![Argo CD pods running after terraform apply](../images/Screenshot%202026-06-21%20at%2019.30.52.png)

### 3. Register the application

```bash
kubectl apply -f supermario-application.yaml
kubectl get applications -n argocd
```

### 4. Access the Argo CD UI

Get the external IP of the Argo CD server service:

```bash
kubectl get svc -n argocd
```

![Argo CD service of type LoadBalancer](../images/kubectl%20get%20svc%20-n%20argo.png)

Retrieve the initial admin password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

Log in at `https://<ARGOCD-EXTERNAL-IP>` with username `admin`.

### 5. Confirm the application is Synced & Healthy

![Argo CD application synced and healthy](../images/ArgoCD%20application%20sync.png)

---

## How the GitOps loop works here

1. The CI pipeline updates the image tag in `k8s/deployment.yaml` and commits it.
2. Argo CD detects the new commit on `main`.
3. Argo CD reconciles the cluster to match Git — **no manual `kubectl apply`**.

To test it yourself, change `replicas` in [`../k8s/deployment.yaml`](../k8s/deployment.yaml), commit, push, and watch Argo CD reconcile automatically.

---

## ➡️ Next step

The application manifests Argo CD manages are documented in [`k8s/README.md`](../k8s/README.md).

---

## 🧹 Teardown

```bash
terraform destroy -auto-approve
```
