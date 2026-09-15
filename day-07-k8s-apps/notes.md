# Day 7: Kubernetes Deployments & Helm

## Topics Covered
- Deployment strategies (RollingUpdate, Recreate, Blue/Green, Canary)
- Rollout history and rollback mechanisms
- Helm package manager architecture
- Helm charts structure and templates
- Creating and customizing Helm charts
- Helm dependencies and subcharts
- Helm hooks and testing
- Helm repositories
- Advanced deployment patterns
- Custom Resource Definitions (CRDs)
- Operators introduction
- GitOps basics (ArgoCD, Flux)
- Blue/Green and Canary deployments with Istio/Flagger

## Resources
- [Kubernetes Deployments Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Helm Documentation](https://helm.sh/docs/)
- [Helm Chart Template Guide](https://helm.sh/docs/chart_template_guide/)
- [Helm Best Practices](https://helm.sh/docs/topics/chart_best_practices/)
- [Awesome Helm Charts](https://github.com/helm/awesome-charts)
- [Operator Framework](https://operatorframework.io/)
- [Argo CD Documentation](https://argo-cd.readthedocs.io/)
- [Flux Documentation](https://fluxcd.io/docs/)
- [Istio Traffic Management](https://istio.io/latest/docs/concepts/traffic-management/)
- [Flagger Progressive Delivery](https://flagger.app/)

## Hands-on Exercises

### Exercise 1: Advanced Deployment Strategies
1. Implement RollingUpdate deployments with monitoring
2. Test Recreate deployment strategy
3. Simulate Blue/Green deployment using Services
4. Create Canary deployment with traffic splitting
5. Configure rollback triggers and alerts

### Exercise 2: Helm Charts Creation
1. Create a basic Helm chart structure
2. Define values.yaml with configurable parameters
3. Use template functions and pipelines
4. Implement conditional logic in templates
5. Create reusable template partials

### Exercise 3: Helm Dependencies and Advanced Features
1. Create umbrella charts with dependencies
2. Use Helm hooks for lifecycle events
3. Implement Helm tests for chart validation
4. Package and publish charts to repositories
5. Use Helm plugins for extended functionality

### Exercise 4: Custom Resource Definitions (CRDs)
1. Create a simple CRD definition
2. Generate CRD from Go struct (conceptual)
3. Implement basic controller logic
4. Use kubebuilder to scaffold operators
5. Test CRD with sample resources

### Exercise 5: GitOps and Progressive Delivery
1. Set up Argo CD or Flux for GitOps
2. Create Git repository with Kubernetes manifests
3. Configure automated sync and drift detection
4. Implement Canary analysis with Flagger
5. Set up promotion criteria and automated rollbacks

## Solutions

<details>
<summary>Exercise 1 Solutions: Advanced Deployment Strategies</summary>

```bash
# 1. Implement RollingUpdate deployments with monitoring
echo "Creating RollingUpdate deployment..."
cat > rolling-update-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rolling-demo
  labels:
    app: rolling-demo
spec:
  replicas: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  selector:
    matchLabels:
      app: rolling-demo
  template:
    metadata:
      labels:
        app: rolling-demo
    spec:
      containers:
      - name: app
        image: nginx:1.19.0
        ports:
        - containerPort: 80
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
EOF

kubectl apply -f rolling-update-deployment.yaml
kubectl rollout status deployment/rolling-demo
kubectl get rs -l app=rolling-demo

# 2. Test Recreate deployment strategy
echo "Testing Recreate deployment strategy..."
cat > recreate-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: recreate-demo
  labels:
    app: recreate-demo
spec:
  replicas: 3
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: recreate-demo
  template:
    metadata:
      labels:
        app: recreate-demo
    spec:
      containers:
      - name: app
        image: nginx:1.19.0
        ports:
        - containerPort: 80
        lifecycle:
          preStop:
            exec:
              command: ["/usr/sbin/nginx", "-s", "quit"]
EOF

kubectl apply -f recreate-deployment.yaml
kubectl rollout status deployment/recreate-demo

# 3. Simulate Blue/Green deployment using Services
echo "Setting up Blue/Green deployment..."
# Create two versions of the application
cat > blue-green-setup.yaml << 'EOF'
---
# Blue version (v1)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-blue
  labels:
    version: v1
    app: webapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webapp
      version: v1
  template:
    metadata:
      labels:
        app: webapp
        version: v1
    spec:
      containers:
      - name: web
        image: nginx:1.19-alpine
        ports:
        - containerPort: 80
        env:
        - name: VERSION
          value: "v1"
---
# Green version (v2)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-green
  labels:
    version: v2
    app: webapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webapp
      version: v2
  template:
    metadata:
      labels:
        app: webapp
        version: v2
    spec:
      containers:
      - name: web
        image: nginx:1.20-alpine
        ports:
        - containerPort: 80
        env:
        - name: VERSION
          value: "v2"
---
# Service that points to active version
apiVersion: v1
kind: Service
metadata:
  name: webapp-service
spec:
  selector:
    app: webapp
    version: v1  # Initially points to blue
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: LoadBalancer
EOF

kubectl apply -f blue-green-setup.yaml
kubectl get deployments -l app=webapp
kubectl get svc webapp-service

# To switch to green version:
# kubectl patch svc webapp-service -p '{"spec":{"selector":{"version":"v2"}}}'

# 4. Create Canary deployment with traffic splitting
echo "Creating Canary deployment with Istio (conceptual)..."
echo "For actual implementation, you would need Istio installed:"
echo ""
echo "# 1. Deploy stable version"
echo "kubectl apply -f canary-stable.yaml"
echo ""
echo "# 2. Deploy canary version"
echo "kubectl apply -f canary-canary.yaml"
echo ""
echo "# 3. Configure Istio VirtualService for traffic splitting"
echo "cat > canary-virtualservice.yaml << 'EOF'"
echo "apiVersion: networking.istio.io/v1alpha3"
echo "kind: VirtualService"
echo "metadata:"
echo "  name: webapp"
echo "spec:"
echo "  hosts:"
echo "  - webapp.example.com"
echo "  http:"
echo "  - route:"
echo "  - destination:"
echo "      host: webapp-stable"
echo "      subset: v1"
echo "      weight: 90"
echo "  - destination:"
echo "      host: webapp-canary"
echo "      subset: v2"
echo "      weight: 10"
echo "EOF"
echo ""
echo "# 4. Gradually increase canary traffic"
echo "# 5. Monitor metrics and rollback if needed"

# 5. Configure rollback triggers and alerts
echo "Setting up rollback monitoring..."
# Monitor deployment rollout
kubectl rollout status deployment/rolling-demo --watch

# Check rollout history
kubectl rollout history deployment/rolling-demo
kubectl rollout history deployment/rolling-demo --revision=2

# Perform rollback
# kubectl rollout undo deployment/rolling-demo
# kubectl rollout undo deployment/rolling-demo --to-revision=3

# Cleanup
kubectl delete -f rolling-update-deployment.yaml recreate-deployment.yaml blue-green-setup.yaml
kubectl delete all --all
```
</details>

<details>
<summary>Exercise 2 Solutions: Helm Charts Creation</summary>

```bash
# 1. Create a basic Helm chart structure
echo "Creating basic Helm chart..."
helm create mywebapp
cd mywebapp

# Chart structure created:
# mywebapp/
# ├── Chart.yaml
# ├── values.yaml
# ├── charts/
# ├── templates/
# │   ├── deployment.yaml
# │   ├── _helpers.tpl
# │   ├── ingress.yaml
# │   ├── service.yaml
# │   └── tests/
# │       └── test-connection.yaml
# └── .helmignore

# 2. Define values.yaml with configurable parameters
echo "Customizing values.yaml..."
cat > values.yaml << 'EOF'
# Default values for mywebapp.
# This is a YAML-formatted file.
# Declare variables to be passed into your templates.

replicaCount: 1

image:
  repository: nginx
  pullPolicy: IfNotPresent
  # Overrides the image tag whose default is the chart appVersion.
  tag: "stable"

imagePullSecrets: []
nameOverride: ""
fullnameOverride: ""

serviceAccount:
  # Specifies whether a service account should be created
  create: true
  # Annotations to add to the service account
  annotations: {}
  # The name of the service account to use.
  # If left unset and create is true, a name will be generated from the fullname
  name: ""

podAnnotations: {}
podSecurityContext: {}
# fsGroup: 20

securityContext: {}
# capabilities:
#   drop:
#   - ALL
# readOnlyRootFilesystem: true
# runAsNonRoot: true
# runAsUser: 1000

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: false
  className: ""
  annotations: {}
  # kubernetes.io/ingress.class: nginx
  # kubernetes.io/tls-acme: "yes"
  hosts:
    - host: chart-example.local
      paths:
        - path: /
          pathType: ImplementationSpecific
  tls: []
  # - secretName: chart-example-tls
  #   hosts:
  #     - chart-example.local

resources: {}
# We usually recommend not to specify default resources and to leave this as a conscious
# choice for the user. This also increases chances resources run on pods with different
# requests and limits.
# limits:
#   cpu: 100m
#   memory: 128Mi
# requests:
#   cpu: 100m
#   memory: 128Mi

nodeSelector: {}
tolerations: []
affinity: {}

# Additional labels
labels: {}

# Additional annotations
annotations: {}
EOF

# 3. Use template functions and pipelines
echo "Customizing templates with template functions..."
cat > templates/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "mywebapp.fullname" . }}
  labels:
    {{- include "mywebapp.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "mywebapp.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      {{- if .Values.podAnnotations }}
      annotations:
        {{- toYaml .Values.podAnnotations | nindent 8 }}
      {{- end }}
      labels:
        {{- include "mywebapp.selectorLabels" . | nindent 8 }}
    spec:
      {{- if .Values.podSecurityContext }}
      securityContext:
        {{- toYaml .Values.podSecurityContext | nindent 8 }}
      {{- end }}
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - name: http
          containerPort: {{ .Values.service.port }}
          protocol: TCP
        {{- if .Values.resources.limits }}
        resources:
          {{- toYaml .Values.resources | nindent 10 }}
        {{- end }}
        {{- if .Values.securityContext }}
        securityContext:
          {{- toYaml .Values.securityContext | nindent 10 }}
        {{- end }}
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml .Values.nodeSelector | nindent 8 }}
      {{- end }}
      {{- with .Values.affinity }}
      affinity:
        {{- toYaml .Values.affinity | nindent 8 }}
      {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml .Values.tolerations | nindent 8 }}
      {{- end }}
EOF

# 4. Implement conditional logic in templates
echo "Adding conditional logic to templates..."
cat > templates/service.yaml << 'EOF'
{{- if .Values.service.enabled }}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "mywebapp.fullname" . }}
  labels:
    {{- include "mywebapp.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.port }}
      protocol: TCP
      name: http
  {{- if .Values.service.nodePort }}
  nodePort: {{ .Values.service.nodePort }}
  {{- end }}
  selector:
    {{- include "mywebapp.selectorLabels" . | nindent 4 }}
{{- end }}
EOF

# Add ingress with conditional enabling
cat > templates/ingress.yaml << 'EOF'
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "mywebapp.fullname" . }}
  labels:
    {{- include "mywebapp.labels" . | nindent 4 }}
  {{- with .Values.ingress.annotations }}
  annotations:
    {{- toYaml .Values.ingress.annotations | nindent 4 }}
  {{- end }}
spec:
  {{- if .Values.ingress.className }}
  ingressClassName: {{ .Values.ingress.className }}
  {{- end }}
  {{- if .Values.ingress.tls }}
  tls:
    {{- toYaml .Values.ingress.tls | nindent 4 }}
  {{- end }}
  spec:
    rules:
      {{- range .Values.ingress.hosts }}
      - host: {{ .host }}
        http:
          paths:
            {{- range .paths }}
            - path: {{ .path }}
              pathType: {{ .pathType }}
              backend:
                service:
                  name: {{ include "mywebapp.fullname" . }}
                  port:
                    number: {{ .Values.service.port }}
            {{- end }}
      {{- end }}
  {{- end }}
EOF

# 5. Create reusable template partials
echo "Creating template helpers and partials..."
cat > templates/_helpers.tpl << 'EOF'
{{-/*
Create the name of the resource as used by Helm.
*/}}
{{- define "mywebapp.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{-/*
Create a default fully qualified app name.
We concatenate the release name with the chart name.
*/}}
{{- define "mywebapp.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end }}
{{- end }}

{{-/*
Common labels
*/}}
{{- define "mywebapp.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{-/*
Selector labels
*/}}
{{- define "mywebapp.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
EOF

# Test the chart
echo "Testing Helm chart..."
helm lint .
helm install mywebapp ./mywebapp
helm get manifest mywebapp
helm status mywebapp

# Cleanup
helm uninstall mywebapp
cd ..
rm -rf mywebapp
```
</details>

<details>
<summary>Exercise 3 Solutions: Helm Dependencies and Advanced Features</summary>

```bash
# 1. Create umbrella charts with dependencies
echo "Creating umbrella chart with dependencies..."
mkdir -p monitoring-stack
cd monitoring-stack

# Create main Chart.yaml
cat > Chart.yaml << 'EOF'
apiVersion: v2
name: monitoring-stack
description: A Helm chart for Kubernetes monitoring stack
type: application
version: 0.1.0
appVersion: "1.0.0"
dependencies:
  - name: prometheus
    version: 11.13.0
    repository: https://prometheus-community.github.io/helm-charts
  - name: grafana
    version: 6.25.0
    repository: https://grafana.github.io/helm-charts
  - name: alertmanager
    version: 0.18.0
    repository: https://prometheus-community.github.io/helm-charts
EOF

# Create values.yaml to configure dependencies
cat > values.yaml << 'EOF'
prometheus:
  prometheusSpec:
    serviceMonitorSelectorNilUsesHelmValues: false
    serviceMonitorSelector: {}
    resources:
      limits:
        cpu: 500m
        memory: 1Gi
      requests:
        cpu: 200m
        memory: 512Mi

grafana:
  adminPassword: grafana
  sidecar:
    dashboards:
      enabled: true
    datasources:
      enabled: true

alertmanager:
  alertmanagerSpec:
    resources:
      limits:
        cpu: 100m
        memory: 256Mi
      requests:
        cpu: 50m
        memory: 128Mi
EOF

# Initialize dependencies
helm dependency update

# 2. Use Helm hooks for lifecycle events
echo "Creating chart with Helm hooks..."
mkdir -p webapp-with-hooks
cd webapp-with-hooks

helm create webapp-with-hooks
cd webapp-with-hooks

# Add pre-install hook
cat > templates/hooks.yaml << 'EOF'
{{- if .Values.hooks.enabled }}
apiVersion: batch/v1
kind: Job
metadata:
  name: "{{ include \"webapp-with-hooks.fullname\" . }}-pre-install"
  labels:
    {{- include \"webapp-with-hooks.labels\" . | nindent 4 }}
  annotations:
    "helm.sh/hook": pre-install
    "helm.sh/hook-weight": "-5"
    "helm.sh/hook-delete-policy": hook-succeeded
spec:
  template:
    metadata:
      {{- if .Values.podAnnotations }}
      annotations:
        {{- toYaml .Values.podAnnotations | nindent 8 }}
      {{- end }}
    spec:
      restartPolicy: OnFailure
      containers:
      - name: pre-install
        image: alpine:latest
        command: ["/bin/sh", "-c"]
        args:
        - |
          echo "Running pre-install tasks..."
          echo "Checking prerequisites..."
          sleep 5
          echo "Pre-install completed."
{{- end }}
EOF

# Add post-install hook
cat >> templates/hooks.yaml << 'EOF'
{{- if .Values.hooks.enabled }}
---
apiVersion: batch/v1
kind: Job
metadata:
  name: "{{ include \"webapp-with-hooks.fullname\" . }}-post-install"
  labels:
    {{- include \"webapp-with-hooks.labels\" . | nindent 4 }}
  annotations:
    "helm.sh/hook": post-install
    "helm.sh/hook-weight": "5"
    "helm.sh/hook-delete-policy": hook-succeeded
spec:
  template:
    metadata:
      {{- if .Values.podAnnotations }}
      annotations:
        {{- toYaml .Values.podAnnotations | nindent 8 }}
      {{- end }}
    spec:
      restartPolicy: OnFailure
      containers:
      - name: post-install
        image: alpine:latest
        command: ["/bin/sh", "-c"]
        args:
        - |
          echo "Running post-install tasks..."
          echo "Verifying installation..."
          sleep 5
          echo "Post-install completed."
{{- end }}
EOF

# 3. Implement Helm tests for chart validation
echo "Adding Helm tests..."
mkdir -p templates/tests

cat > templates/tests/test-connection.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: "{{ include \"webapp-with-hooks.fullname\" . }}-test-connection"
  labels:
    {{- include \"webapp-with-hooks.labels\" . | nindent 4 }}
  annotations:
    "helm.sh/hook": test
spec:
  restartPolicy: Never
  containers:
  - name: test
    image: appropriate/curl
    command:
    - /bin/sh
    - -c
    - |
      echo "Testing connection to {{ include \"webapp-with-hooks.fullname\" . }}..."
      HTTP_STATUS=$(curl -s -o /dev/null -w \"%{http_code}\" http://localhost:80 || echo "000")
      if [ ${HTTP_STATUS} -eq 200 ]; then
        echo "Connection test passed"
        exit 0
      else
        echo "Connection test failed with status ${HTTP_STATUS}"
        exit 1
      fi
EOF

# 4. Package and publish charts to repositories
echo "Packaging Helm chart..."
helm package .
# Creates webapp-with-hooks-0.1.0.tgz

# To publish to a repository:
# helm repo add mycharts http://example.com/charts
# helm push webapp-with-hooks-0.1.0.tgz mycharts
# or for GitHub Pages:
# git clone https://github.com/username/username.github.io.git
# cp webapp-with-hooks-0.1.0.tgz username.github.io/charts/
# helm repo index username.github.io/charts --url https://username.github.io/charts
# git add .
# git commit -m "Add webapp-with-hooks chart"
# git push

# 5. Use Helm plugins for extended functionality
echo "Installing useful Helm plugins..."
# helm plugin install https://github.com/databus23/helm-diff
# helm plugin install https://github.com/chartmuseum/helm-push
# helm plugin install https://github.com/aslafy-z/helm-git
# helm plugin install https://github.com/jkroepke/helm-secrets

# Test the chart with hooks
echo "Testing chart with hooks..."
helm install mywebapp . --set hooks.enabled=true
helm test mywebapp

# Cleanup
helm uninstall mywebapp
cd ../..
rm -rf monitoring-stack webapp-with-hooks
```
</details>

<details>
<summary>Exercise 4 Solutions: Custom Resource Definitions (CRDs)</summary>

```bash
# 1. Create a simple CRD definition
echo "Creating a simple CRD for a WebApplication resource..."
cat > webapp-crd.yaml << 'EOF'
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: webapplications.example.com
spec:
  group: example.com
  versions:
    - name: v1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                replicaCount:
                  type: integer
                  minimum: 1
                image:
                  type: string
                port:
                  type: integer
                  minimum: 1
                  maximum: 65535
  scope: Namespaced
  names:
    plural: webapplications
    singular: webapplication
    kind: WebApplication
    shortNames:
    - webapp
EOF

kubectl apply -f webapp-crd.yaml
kubectl get crd webapplications.example.com

# 2. Generate CRD from Go struct (conceptual)
echo "CRD generation from Go struct (conceptual example):"
echo "// In Go, you would define:"
echo "type WebApplicationSpec struct {"
echo "    ReplicaCount int    \`json:\"replicaCount,omitempty\"\`"
echo "    Image        string \`json:\"image,omitempty\"\`"
echo "    Port         int    \`json:\"port,omitempty\"\`"
echo "}"
echo ""
echo "type WebApplication struct {"
echo "    metav1.TypeMeta   \`json:\",inline\"\`"
echo "    metav1.ObjectMeta \`json:\"metadata,omitempty\"\`"
echo "    Spec              WebApplicationSpec \`json:\"spec,omitempty\"\`"
echo "}"
echo ""
echo "# Then use controller-gen to generate CRD:"
echo "# controller-gen crd:trivialVersions=true paths=./... output:crd:artifacts:config=crd/bases"

# 3. Implement basic controller logic (conceptual)
echo "Basic controller logic (conceptual):"
echo "1. Watch for WebApplication resources"
echo "2. For each WebApplication:"
echo "   - Validate spec"
echo "   - Generate Deployment manifest"
echo "   - Generate Service manifest"
echo "   - Apply manifests using Kubernetes client"
echo "3. Update WebApplication status with observed state"
echo ""
echo "# Using client-go:"
echo "watcher, err := kube.Informers.ForResource(gvr).Informer().AddEventHandler(cache.ResourceEventHandlerFuncs{"
echo "    AddFunc:    func(obj interface{}) { reconcile(obj) }"
echo "    UpdateFunc: func(oldObj, newObj interface{}) { reconcile(newObj) }"
echo "    DeleteFunc: func(obj interface{}) { /* cleanup */ }"
echo "})"

# 4. Use kubebuilder to scaffold operators
echo "Using kubebuilder to scaffold operator:"
echo "# Install kubebuilder"
echo "curl -L -o kubebuilder https://go.kubebuilder.io/dl/latest/$(go env GOOS)/$(go env GOARCH)"
echo "chmod +x kubebuilder && sudo mv kubebuilder /usr/local/bin/"
echo ""
echo "# Scaffold new API"
echo "kubebuilder init --domain example.com"
echo "kubebuilder create api --group example --version v1 --kind WebApplication"
echo ""
echo "# This creates:"
echo "- api/v1/webapplication_types.go (Go structs)"
echo "- controllers/webapplication_controller.go (reconciliation logic)"
echo "- config/crd/bases/example.com_webapplications.yaml (CRD manifest)"
echo ""
echo "# Implement reconciliation logic in controller"
echo "# Build and deploy operator:"
echo "make install run"

# 5. Test CRD with sample resources
echo "Testing CRD with sample WebApplication resource..."
cat > webapp-sample.yaml << 'EOF'
apiVersion: example.com/v1
kind: WebApplication
metadata:
  name: my-webapp
  labels:
    app: my-webapp
spec:
  replicaCount: 3
  image: nginx:latest
  port: 80
EOF

kubectl apply -f webapp-sample.yaml
kubectl get webapplications.example.com
kubectl get webapplication my-webapp -o yaml

# Cleanup
kubectl delete -f webapp-crd.yaml webapp-sample.yaml
```
</details>

<details>
<summary>Exercise 5 Solutions: GitOps and Progressive Delivery</summary>

```bash
# 1. Set up Argo CD or Flux for GitOps
echo "Setting up Argo CD for GitOps..."
# Install Argo CD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Alternative: Using Helm
# helm repo add argo https://argoproj.github.io/argo-helm
# helm install argocd argo/argo-cd --namespace argocd

# Wait for Argo CD to be ready
echo "Waiting for Argo CD to be ready..."
kubectl wait --namespace argocd \
  --for=condition=available deployment/argocd-server \
  --timeout=120s

# Expose Argo CD server (for local access)
kubectl port-forward svc/argocd-server -n argocd 8080:443 &
# Access at https://localhost:8080
# Initial admin password:
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# 2. Create Git repository with Kubernetes manifests
echo "Setting up Git repository for GitOps..."
# Create local Git repo
mkdir -p gitops-repo
cd gitops-repo
git init

# Create application manifests
mkdir -p applications
cat > applications/webapp-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  labels:
    app: webapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: webapp
        image: nginx:1.21.0
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
EOF

cat > applications/webapp-service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: webapp
  labels:
    app: webapp
spec:
  selector:
    app: webapp
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: ClusterIP
EOF

# Add and commit manifests
git add .
git commit -m "Initial commit: WebApp manifests"

# 3. Configure automated sync and drift detection
echo "Creating Argo CD Application..."
cat > argocd-application.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: webapp
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/username/gitops-repo.git
    targetRevision: HEAD
    path: applications
  destination:
    server: https://kubernetes.default.svc
    namespace: webapp
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF

kubectl apply -f argocd-application.yaml
kubectl get application webapp -n argocd

# Check sync status
kubectl get application webapp -n argocd -o yaml | grep -A 10 sync

# 4. Implement Canary analysis with Flagger
echo "Setting up Flagger for Canary analysis..."
# Install Flagger (requires Istio or Linkerd)
echo "# For Istio-based Canary:"
echo "helm repo add flagger https://flagger.app"
echo "helm install flagger flagger/flagger \\"
echo "  --namespace=istio-system \\"
echo "  --set meshProvider=istio \\"
echo "  --set metricsServer=http://prometheus:9090"
echo ""
echo "# Create Canary analysis template"
echo "cat > canary-analysis.yaml << 'EOF'"
echo "apiVersion: flagger.app/v1beta1"
echo "kind: Canary"
echo "metadata:"
echo "  name: webapp"
echo "  namespace: webapp"
echo "spec:"
echo "  targetRef:"
echo "    apiVersion: apps/v1"
echo "    kind: Deployment"
echo "  progressDeadlineSeconds: 60"
echo "  service:"
echo "    port: 80"
echo "    targetPort: 80"
echo "  analysis:"
echo "    interval: 1m"
echo "    threshold: 5"
echo "    maxWeight: 50"
echo "    stepWeight: 10"
echo "    metrics:"
echo "    - name: request-success"
echo "      thresholdRange:"
echo "        min: 99"
echo "      interval: 1m"
echo "    - name: request-duration"
echo "      thresholdRange:"
echo "        max: 500"
echo "      interval: 1m"
echo "EOF"

# 5. Set up promotion criteria and automated rollbacks
echo "Configuring promotion criteria and rollbacks..."
echo "# Argo CD Application with health checks"
echo "cat > argocd-healthy-app.yaml << 'EOF'"
echo "apiVersion: argoproj.io/v1alpha1"
echo "kind: Application"
echo "metadata:"
echo "  name: webapp-promoted"
echo "  namespace: argocd"
echo "spec:"
echo "  project: default"
echo "  source:"
echo "    repoURL: https://github.com/username/gitops-repo.git"
echo "    targetRevision: HEAD"
echo "    path: applications"
echo "  destination:"
echo "    server: https://kubernetes.default.svc"
echo "    namespace: webapp-promoted"
echo "  syncPolicy:"
echo "    automated:"
echo "      prune: true"
echo "      selfHeal: true"
echo "    syncOptions:"
echo "    - CreateNamespace=true"
echo "  healthChecks:"
echo "  - type: pod"
echo "    name: webapp"
echo "    namespace: webapp-promoted"
echo "EOF"

# Cleanup
cd ..
rm -rf gitops-repo
kubectl delete namespace argocd webapp webapp-promoted --ignore-not-found
kubectl delete application webapp webapp-promoted -n argocd --ignore-not-found
```
</details>