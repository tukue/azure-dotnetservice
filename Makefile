.PHONY: build test run docker-build docker-run kind-up kind-load kind-deploy kind-down kind-demo clean

APP_NAME   := cloud-native-microservice
K8S_DIR    := deploy/k8s
TAG        := local

# ── .NET ──────────────────────────────────────────────────

build:
	dotnet build src/$(APP_NAME)/$(APP_NAME).csproj -c Release

test:
	dotnet test src/$(APP_NAME)/$(APP_NAME).csproj -c Release --verbosity normal

run:
	dotnet run --project src/$(APP_NAME)/$(APP_NAME).csproj

# ── Docker ────────────────────────────────────────────────

docker-build:
	docker build -t $(APP_NAME):$(TAG) .

docker-run: docker-build
	docker run --rm -p 8080:8080 --name $(APP_NAME) $(APP_NAME):$(TAG)

# ── Kind (Kubernetes in Docker) ──────────────────────────

CLUSTER_NAME ?= microservice-cluster

kind-up:
	@if ! kind get clusters 2>/dev/null | grep -q "^$(CLUSTER_NAME)$$"; then \
		echo "Creating Kind cluster '$(CLUSTER_NAME)'..."; \
		kind create cluster --name $(CLUSTER_NAME); \
	else \
		echo "Kind cluster '$(CLUSTER_NAME)' already exists."; \
	fi

kind-load: docker-build kind-up
	kind load docker-image $(APP_NAME):$(TAG) --name $(CLUSTER_NAME)

kind-deploy: kind-load
	kubectl kustomize $(K8S_DIR)/overlays/kind | kubectl apply -f -
	kubectl rollout status deployment/$(APP_NAME) -n $(APP_NAME) --timeout=120s
	@echo ""
	@echo "Application deployed! Access it via:"
	@echo "  kubectl port-forward -n $(APP_NAME) svc/$(APP_NAME) 8080:80"

kind-test:
	@echo ""
	@echo "Testing endpoints..."
	@kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=$(APP_NAME) -n $(APP_NAME) --timeout=60s
	@kubectl port-forward -n $(APP_NAME) svc/$(APP_NAME) 8080:80 & \
	PF_PID=$$!; \
	sleep 3; \
	echo "── Weather API ──────────────────────────────"; \
	curl -s http://localhost:8080/api/weather | head -c 500; \
	echo ""; \
	echo "── Health Check ────────────────────────────"; \
	curl -s -o /dev/null -w "HTTP %{http_code}\n" http://localhost:8080/health; \
	kill $$PF_PID 2>/dev/null || true

kind-demo: kind-deploy kind-test
	@echo ""
	@echo "✓ Full demo complete! Run 'make kind-down' to clean up."

kind-down:
	-kubectl delete deployment $(APP_NAME) -n $(APP_NAME) 2>/dev/null || true
	-kubectl delete service $(APP_NAME) -n $(APP_NAME) 2>/dev/null || true
	-kubectl delete namespace $(APP_NAME) 2>/dev/null || true
	@echo "Cleaned up."

kind-destroy:
	kind delete cluster --name $(CLUSTER_NAME)

# ── ArgoCD ────────────────────────────────────────────────

ARGOCD_DIR := argocd

argocd-apply:
	kubectl apply -k $(ARGOCD_DIR)

argocd-apply-prod:
	kubectl apply -f $(ARGOCD_DIR)/project.yaml
	kubectl apply -f $(ARGOCD_DIR)/application.yaml

argocd-apply-dev:
	kubectl apply -f $(ARGOCD_DIR)/application-dev.yaml

argocd-apply-kind:
	kubectl apply -f $(ARGOCD_DIR)/application-kind.yaml

argocd-delete:
	kubectl delete -k $(ARGOCD_DIR)

argocd-status:
	kubectl get applications -n argocd

# ── Kustomize ────────────────────────────────────────────

kustomize-dev:
	kubectl kustomize $(K8S_DIR)/overlays/dev

kustomize-prod:
	kubectl kustomize $(K8S_DIR)/overlays/prod

kustomize-kind:
	kubectl kustomize $(K8S_DIR)/overlays/kind

# ── Clean ─────────────────────────────────────────────────

clean:
	rm -rf publish/
	dotnet clean src/$(APP_NAME)/$(APP_NAME).csproj
	-docker rmi $(APP_NAME):$(TAG) 2>/dev/null || true
