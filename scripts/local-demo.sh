#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────
# Local demo script — runs the full CI/CD flow locally
# without an Azure subscription.
#
# Uses Kustomize overlays to deploy to Kind, following
# GitOps best practices.
#
# Prerequisites: docker, kind, kubectl, kustomize, dotnet SDK 8.0
# ──────────────────────────────────────────────────────────
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CLUSTER_NAME="${1:-microservice-cluster}"
APP_NAME="cloud-native-microservice"
KUSTOMIZE_OVERLAY="deploy/k8s/overlays/kind"

echo "══════════════════════════════════════════════"
echo "  Cloud-Native .NET Microservice — Local Demo"
echo "══════════════════════════════════════════════"

# Step 1: Build and test .NET app
echo ""
echo "▸ Step 1/5: Building .NET application..."
dotnet restore "src/${APP_NAME}/${APP_NAME}.csproj"
dotnet build "src/${APP_NAME}/${APP_NAME}.csproj" -c Release --no-restore
dotnet test "src/${APP_NAME}/${APP_NAME}.csproj" -c Release --no-build --verbosity normal

# Step 2: Build Docker image
echo ""
echo "▸ Step 2/5: Building Docker image..."
docker build -t "${APP_NAME}:local" .

# Step 3: Create Kind cluster
echo ""
echo "▸ Step 3/5: Creating Kind cluster..."
if ! kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
  kind create cluster --name "${CLUSTER_NAME}"
fi

# Step 4: Load image and deploy via Kustomize
echo ""
echo "▸ Step 4/5: Deploying to Kind via Kustomize..."
kind load docker-image "${APP_NAME}:local" --name "${CLUSTER_NAME}"

kubectl kustomize "${KUSTOMIZE_OVERLAY}" | kubectl apply -f -
kubectl rollout status "deployment/${APP_NAME}" -n "${APP_NAME}" --timeout=120s

# Step 5: Test
echo ""
echo "▸ Step 5/5: Testing endpoints..."
kubectl wait --for=condition=ready pod -l "app.kubernetes.io/name=${APP_NAME}" -n "${APP_NAME}" --timeout=60s
kubectl port-forward -n "${APP_NAME}" "svc/${APP_NAME}" 8080:80 &
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
