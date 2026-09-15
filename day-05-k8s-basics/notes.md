# Day 5: Kubernetes Basics

## Topics Covered
- Kubernetes architecture (master/node components)
- Pods: the smallest deployable units
- Labels and selectors
- ReplicaSets and Deployments
- Services (ClusterIP, NodePort, LoadBalancer)
- Namespaces
- Imperative vs Declarative management
- kubectl essential commands
- YAML manifests structure
- Resource quotas and limits
- Basic troubleshooting with kubectl

## Resources
- [Kubernetes Basics Interactive Tutorial](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
- [Kubernetes Documentation - Concepts](https://kubernetes.io/docs/concepts/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Kubernetes the Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way)
- [Play with Kubernetes](https://labs.play-with-k8s.com/)
- [Katacoda Kubernetes Scenarios](https://www.katacoda.com/courses/kubernetes)
- [Kubernetes.io Documentation](https://kubernetes.io/docs/home/)

## Hands-on Exercises

### Exercise 1: Kubernetes Setup and kubectl
1. Install kubectl and set up a local cluster (Minikube/kind)
2. Verify cluster status and node information
3. Practice essential kubectl commands
4. Get help and use kubectl completion
5. Configure kubectl aliases and shortcuts

### Exercise 2: Pods and Labels
1. Create and manage pods imperatively and declaratively
2. Apply labels and selectors to pods
3. Use label-based filtering and grouping
4. Update labels on existing pods
5. Delete pods using label selectors

### Exercise 3: ReplicaSets and Deployments
1. Create ReplicaSets manually
2. Create Deployments for rolling updates
3. Scale deployments up and down
4. Perform rollout history and rollback
5. Configure deployment strategies

### Exercise 4: Services and Networking
1. Create ClusterIP, NodePort, and LoadBalancer services
2. Expose deployments through services
3. Test service discovery with DNS
4. Configure service annotations
5. Implement headless services

### Exercise 5: Namespaces and Resource Management
1. Create and manage namespaces
2. Set resource quotas and limits
3. Apply limit ranges to namespaces
4. Configure resource requests and limits
5. Quota monitoring and alerting

## Solutions

<details>
<summary>Exercise 1 Solutions: Kubernetes Setup and kubectl</summary>

```bash
# 1. Install kubectl and set up a local cluster
echo "Installing kubectl..."
# Linux AMD64
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verify installation
kubectl version --client

# 2. Set up local cluster with Minikube
echo "Setting up Minikube cluster..."
# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Start Minikube
minikube start --driver=docker

# Alternative: kind (Kubernetes IN Docker)
# curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
# chmod +x ./kind
# sudo mv ./kind /usr/local/bin/kind
# kind create cluster

# 3. Verify cluster status and node information
echo "Checking cluster status..."
kubectl cluster-info
kubectl get nodes
kubectl get nodes -o wide
kubectl describe nodes

# 4. Practice essential kubectl commands
echo "Practicing kubectl commands..."
# Get all resources in default namespace
kubectl get all

# Get specific resource types
kubectl get pods
kubectl get services
kubectl get deployments
kubectl get replicasets

# Watch resources
kubectl get pods -w

# 5. Get help and use kubectl completion
echo "Getting help and setting up completion..."
kubectl help
kubectl get --help

# Bash completion
echo 'source <(kubectl completion bash)' >> ~/.bashrc
source <(kubectl completion bash)

# Zsh completion
# echo 'source <(kubectl completion zsh)' >> ~/.zshrc
# source <(kubectl completion zsh)

# 6. Configure kubectl aliases and shortcuts
echo "Setting up kubectl aliases..."
echo 'alias k=kubectl' >> ~/.bashrc
echo 'alias kgp="kubectl get pods"' >> ~/.bashrc
echo 'alias kgs="kubectl get services"' >> ~/.bashrc
echo 'alias kgd="kubectl get deployments"' >> ~/.bashrc
echo 'alias kl="kubectl logs"' >> ~/.bashrc
echo 'alias ke="kubectl exec -it"' >> ~/.bashrc
source ~/.bashrc
```
</details>

<details>
<summary>Exercise 2 Solutions: Pods and Labels</summary>

```bash
# 1. Create and manage pods imperatively and declaratively
echo "Creating pods imperatively..."
kubectl run nginx --image=nginx:latest --restart=Never
kubectl run busybox --image=busybox:latest --restart=Never -- sleep 3600

echo "Listing pods..."
kubectl get pods
kubectl get pods -o wide

# 2. Apply labels and selectors to pods
echo "Creating labeled pods declaratively..."
cat > labeled-pod.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: web-frontend
  labels:
    app: web
    tier: frontend
    environment: production
    version: v1.2.3
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    ports:
    - containerPort: 80
EOF

kubectl apply -f labeled-pod.yaml

# 3. Use label-based filtering and grouping
echo "Filtering pods by labels..."
kubectl get pods --show-labels
kubectl get pods -l app=web
kubectl get pods -l environment=production
kubectl get pods -l 'tier in (frontend,backend)'
kubectl get pods -l 'environment notin (development)'
kubectl get pods -l 'version,version!='  # Has version key, any value

# 4. Update labels on existing pods
echo "Updating labels on existing pods..."
kubectl label pod web-frontend version=v1.2.4 --overwrite
kubectl label pod web-frontend environment=staging --overwrite
kubectl label pod web-frontend team- --overwrite  # Remove label

# Verify label changes
kubectl get pod web-frontend --show-labels

# 5. Delete pods using label selectors
echo "Deleting pods with label selectors..."
kubectl delete pods -l app=web
kubectl delete pods -l environment=staging
kubectl delete pods --all  # Delete all pods in namespace

# Cleanup
kubectl delete pod nginx busybox web-frontend --ignore-not-found
```
</details>

<details>
<summary>Exercise 3 Solutions: ReplicaSets and Deployments</summary>

```bash
# 1. Create ReplicaSets manually
echo "Creating ReplicaSet manifest..."
cat > frontend-replicaset.yaml << 'EOF'
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: frontend
  labels:
    app: guestbook
    tier: frontend
spec:
  # modify replicas according to your case
  replicas: 3
  selector:
    matchLabels:
      tier: frontend
  template:
    metadata:
      labels:
        tier: frontend
    spec:
      containers:
      - name: php-redis
        image: gcr.io/google_samples/gb-frontend:v3
        env:
        - name: GET_HOSTS_FROM
          value: dns
          # If your cluster configuration does not include a dns service, then to
          # instead access environment variables to find service host
          # info, comment out the 'value: dns' line above, and uncomment the line
          # below.
          # value: env
        ports:
        - containerPort: 80
EOF

kubectl apply -f frontend-replicaset.yaml
kubectl get replicaset
kubectl get pods -l app=guestbook

# 2. Create Deployments for rolling updates
echo "Creating Deployment for rolling updates..."
cat > nginx-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
EOF

kubectl apply -f nginx-deployment.yaml
kubectl get deployment
kubectl get rs
kubectl get pods -l app=nginx

# 3. Scale deployments up and down
echo "Scaling deployments..."
kubectl scale deployment/nginx-deployment --replicas=5
kubectl get deployment nginx-deployment

kubectl scale deployment/nginx-deployment --replicas=2
kubectl get deployment nginx-deployment

# Alternative scaling method
kubectl edit deployment/nginx-deployment  # Edit replicas field manually

# 4. Perform rollout history and rollback
echo "Performing rolling update and rollback..."
# Update deployment image
kubectl set image deployment/nginx-deployment nginx=nginx:1.16.1
# or
kubectl patch deployment/nginx-deployment -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx","image":"nginx:1.16.1"}]}}}}'

# Check rollout status
kubectl rollout status deployment/nginx-deployment
kubectl rollout history deployment/nginx-deployment

# Rollback to previous version
kubectl rollout undo deployment/nginx-deployment
# Rollback to specific revision
# kubectl rollout undo deployment/nginx-deployment --to-revision=2

# 5. Configure deployment strategies
echo "Testing different deployment strategies..."
cat > deployment-strategy.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: strategy-demo
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  selector:
    matchLabels:
      app: strategy-demo
  template:
    metadata:
      labels:
        app: strategy-demo
    spec:
      containers:
      - name: app
        image: nginx:alpine
        ports:
        - containerPort: 80
EOF

kubectl apply -f deployment-strategy.yaml

# To test Recreate strategy:
# strategy:
#   type: Recreate

# Cleanup
kubectl delete -f frontend-replicaset.yaml nginx-deployment.yaml deployment-strategy.yaml
kubectl delete all --all
```
</details>

<details>
<summary>Exercise 4 Solutions: Services and Networking</summary>

```bash
# 1. Create ClusterIP, NodePort, and LoadBalancer services
echo "Creating sample deployment for service testing..."
kubectl create deployment hello-node --image=gcr.io/google-samples/hello-app:1.0
kubectl expose deployment hello-node --port=8080 --type=ClusterIP

# 2. Expose deployments through services
echo "Creating different service types..."
# ClusterIP (default)
kubectl expose deployment hello-node --name=hello-clusterip --port=8080 --type=ClusterIP

# NodePort
kubectl expose deployment hello-node --name=hello-nodeport --port=8080 --type=NodePort

# LoadBalancer (will stay pending in local clusters without LB provider)
kubectl expose deployment hello-node --name=hello-loadbalancer --port=8080 --type=LoadBalancer

# 3. Test service discovery with DNS
echo "Testing service discovery..."
# Get service details
kubectl get services hello-node
kubectl get svc hello-node -o wide

# Access service via ClusterIP
CLUSTER_IP=$(kubectl get svc hello-node -o jsonpath='{.spec.clusterIP}')
PORT=$(kubectl get svc hello-node -o jsonpath='{.spec.ports[0].port}')
echo "Accessing service at $CLUSTER_IP:$PORT"
curl http://$CLUSTER_IP:$PORT

# Access service via DNS name within cluster
# Create a temporary pod to test DNS
kubectl run -it --rm dns-test --image=alpine:latest -- sh -c "
  apk add --no-cache bind-tools
  nslookup hello-node
  dig hello-node
  wget -qO- http://hello-node:8080
"

# 4. Configure service annotations
echo "Adding annotations to service..."
kubectl annotate service hello-node \
  description="Hello World application service" \
  owner="devops-team" \
  version="1.0.0"

kubectl get service hello-node -o yaml | grep -A 5 annotations

# 5. Implement headless services
echo "Creating headless service for StatefulSet-like behavior..."
cat > headless-service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: headless-service
  labels:
    app: myapp
spec:
  clusterIP: None  # This makes it headless
  selector:
    app: myapp
  ports:
  - port: 80
    name: http
EOF

kubectl apply -f headless-service.yaml
kubectl get svc headless-service

# Test headless service DNS
kubectl run -it --rm dns-test2 --image=alpine:latest -- sh -c "
  apk add --no-cache bind-tools
  nslookup headless-service
  # Should return multiple IPs if multiple pods match selector
"

# Cleanup
kubectl delete deployment hello-node
kubectl delete service hello-node hello-clusterip hello-nodeport hello-loadbalancer headless-service
```
</details>

<details>
<summary>Exercise 5 Solutions: Namespaces and Resource Management</summary>

```bash
# 1. Create and manage namespaces
echo "Creating namespaces..."
kubectl create namespace dev
kubectl create namespace staging
kubectl create namespace production

kubectl get namespaces

# 2. Set resource quotas and limits
echo "Setting resource quotas..."
cat > dev-quota.yaml << 'EOF'
apiVersion: v1
kind: ResourceQuota
metadata:
  name: dev-quota
  namespace: dev
spec:
  hard:
    requests.cpu: "1"
    requests.memory: 1Gi
    limits.cpu: "2"
    limits.memory: 2Gi
    pods: "10"
    services: "5"
    replicationcontrollers: "10"
    resourcequotas: "1"
    secrets: "20"
    configmaps: "10"
    persistentvolumeclaims: "5"
EOF

kubectl apply -f dev-quota.yaml
kubectl get resourcequota -n dev

# 3. Apply limit ranges to namespaces
echo "Setting limit ranges..."
cat > dev-limitrange.yaml << 'EOF'
apiVersion: v1
kind: LimitRange
metadata:
  name: dev-limitrange
  namespace: dev
spec:
  limits:
  - default:
      cpu: 500m
      memory: 512Mi
    defaultRequest:
      cpu: 250m
      memory: 256Mi
    max:
      cpu: "1"
      memory: 1Gi
    min:
      cpu: 100m
      memory: 64Mi
    type: Container
EOF

kubectl apply -f dev-limitrange.yaml
kubectl get limitrange -n dev

# 4. Configure resource requests and limits
echo "Creating pods with resource requests/limits..."
cat > resource-demo-pod.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: resource-demo
  namespace: dev
spec:
  containers:
  - name: app
    image: nginx:alpine
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "500m"
    ports:
    - containerPort: 80
EOF

kubectl apply -f resource-demo-pod.yaml -n dev
kubectl get pod resource-demo -n dev -o yaml | grep -A 10 resources

# 5. Quota monitoring and alerting
echo "Checking quota usage..."
kubectl describe resourcequota dev-quota -n dev

# Simulate resource usage to test quota
echo "Testing quota limits..."
# This should succeed (within limits)
kubectl run -n dev --rm busybox-test --image=busybox -- sleep 300

# Check updated quota usage
kubectl describe resourcequota dev-quota -n dev

# Cleanup
kubectl delete namespace dev staging production
kubectl delete all --all
```
</details>