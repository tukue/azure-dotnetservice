#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────
# Local demo script — runs the full CI/CD flow locally
# without an Azure subscription.
#
# Prerequisites: docker, kind, kubectl, dotnet SDK 8.0
# ──────────────────────────────────────────────────────────
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CLUSTER_NAME="${1:-microservice-cluster}"

echo "══════════════════════════════════════════════"
echo "  Cloud-Native .NET Microservice — Local Demo"
echo "══════════════════════════════════════════════"

# Step 1: Build and test .NET app
echo ""
echo "▸ Step 1/5: Building .NET application..."
dotnet restore src/CloudNativeMicroservice/CloudNativeMicroservice.csproj
dotnet build src/CloudNativeMicroservice/CloudNativeMicroservice.csproj -c Release --no-restore
dotnet test src/CloudNativeMicroservice/CloudNativeMicroservice.csproj -c Release --no-build --verbosity normal

# Step 2: Build Docker image
echo ""
echo "▸ Step 2/5: Building Docker image..."
docker build -t cloud-native-microservice:local .

# Step 3: Create Kind cluster
echo ""
echo "▸ Step 3/5: Creating Kind cluster..."
if ! kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
  kind create cluster --name "${CLUSTER_NAME}"
fi

# Step 4: Load image and deploy
echo ""
echo "▸ Step 4/5: Deploying to Kind..."
kind load docker-image cloud-native-microservice:local --name "${CLUSTER_NAME}"

# Patch the image tag in deployment.yaml (save original)
cp deploy/k8s/deployment.yaml deploy/k8s/deployment.yaml.bak
sed -i "s|__IMAGE__|cloud-native-microservice:local|g" deploy/k8s/deployment.yaml

kubectl apply -f deploy/k8s/deployment.yaml
kubectl apply -f deploy/k8s/service.yaml
kubectl rollout status deployment/cloud-native-microservice --timeout=120s

# Restore original
mv deploy/k8s/deployment.yaml.bak deploy/k8s/deployment.yaml

# Step 5: Test
echo ""
echo "▸ Step 5/5: Testing endpoints..."
kubectl port-forward svc/cloud-native-microservice 8080:80 &
PF_PID=$!
sleep 3

echo ""
echo "── Weather API ──────────────────────────────────"
curl -s http://localhost:8080/api/weather | python3 -m json.tool 2>/dev/null || curl -s http://localhost:8080/api/weather

echo ""
echo "── Health Check ────────────────────────────────"
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://localhost:8080/health

kill $PF_PID 2>/dev/null || true

echo ""
echo "══════════════════════════════════════════════"
echo "  Demo complete!"
  echo "  Run 'kind delete cluster --name ${CLUSTER_NAME}' to"
echo "  tear down the local cluster."
echo "══════════════════════════════════════════════"
