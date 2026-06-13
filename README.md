# Cloud-Native .NET Microservice — Azure Hands-On Showcase

[![Build and Deploy to AKS](https://github.com/your-org/azure-dotnetservice/actions/workflows/deploy.yml/badge.svg)](https://github.com/your-org/azure-dotnetservice/actions/workflows/deploy.yml)

A showcase repository demonstrating containerized .NET microservice deployment to **Azure Kubernetes Service (AKS)** with **GitHub Actions** and **Azure Pipelines** — designed to run fully offline with Kind when no Azure subscription is available.

## What's Demonstrated

| Capability | Live Azure | Local (Kind) |
|------------|:----------:|:-------------:|
| .NET build & test | ✅ | ✅ |
| Docker container build | ✅ | ✅ |
| Push to Azure Container Registry | ✅ | — |
| Deploy to AKS | ✅ | — |
| Deploy to local Kind cluster | — | ✅ |
| Rolling updates & health probes | ✅ | ✅ |
| GitHub Actions CI/CD | ✅ | ✅ (build + dry-run) |
| Azure Pipelines CI/CD | ✅ | ✅ (build + dry-run) |

## Project Structure

```
.
├── src/CloudNativeMicroservice/     # .NET 8 Web API
├── .github/workflows/deploy.yml     # GitHub Actions pipeline
├── azure-pipelines.yml              # Azure DevOps pipeline
├── deploy/k8s/                      # Kubernetes manifests
├── scripts/local-demo.sh            # Full local demo script
├── docker-compose.yml               # Local container testing
├── Dockerfile                       # Multi-stage container build
└── Makefile                         # Task runner
```

## Run Without Azure

### Prerequisites

- [Docker](https://docker.com)
- [Kind](https://kind.sigs.k8s.io) — `go install sigs.k8s.io/kind@latest`
- [.NET 8 SDK](https://dotnet.microsoft.com/download)

### One-command demo

```bash
make kind-demo
```

This runs the full flow: builds the app → runs tests → builds Docker image → creates a Kind cluster → deploys the K8s manifests → tests the API endpoint.

### Step by step

```bash
# Build and test locally
make build && make test

# Run via Docker
make docker-run

# Deploy to local Kind cluster
make kind-up
make kind-deploy

# Tear down
make kind-destroy
```

### Manual script

```bash
./scripts/local-demo.sh
```

## Deploy to Azure (when subscription is available)

### GitHub Actions

Set these [repository secrets](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions):

| Secret | Purpose |
|--------|---------|
| `AZURE_CREDENTIALS` | Azure service principal (JSON) |
| `ACR_LOGIN_SERVER` | e.g. `myacr.azurecr.io` |
| `ACR_USERNAME` | ACR admin username |
| `ACR_PASSWORD` | ACR admin password |
| `AKS_CLUSTER_NAME` | AKS cluster name |
| `AKS_RESOURCE_GROUP` | AKS resource group |

The workflow runs **build + test** unconditionally, and only pushes to ACR / deploys to AKS when secrets are present.

### Azure Pipelines

Set pipeline variables (`acrLoginServer`, `aksClusterName`, etc.) via the Azure DevOps portal. The pipeline conditionally skips the Deploy stage if AKS isn't configured.

## Kubernetes Manifests

| File | Description |
|------|-------------|
| `deployment.yaml` | 3 replicas, RollingUpdate, `/health` probes, resource limits |
| `service.yaml` | LoadBalancer exposing port 80 → container port 8080 |
