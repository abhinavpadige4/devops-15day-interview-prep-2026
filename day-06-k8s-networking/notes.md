# Day 6: Kubernetes Networking & Services

## Topics Covered
- Kubernetes networking model
- Pod-to-pod communication
- Service types deep dive (ClusterIP, NodePort, LoadBalancer, ExternalName)
- Service discovery and DNS
- Ingress controllers and resources
- Network policies
- CNI plugins (Calico, Flannel, Weave, etc.)
- Service mesh introduction (Istio, Linkerd)
- Load balancing strategies
- External traffic policies
- Session affinity
- Headless services
- Multi-cluster networking concepts

## Resources
- [Kubernetes Networking Documentation](https://kubernetes.io/docs/concepts/cluster-administration/networking/)
- [Services, Load Balancing, and Networking](https://kubernetes.io/docs/concepts/services-networking/service/)
- [Ingress Documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [CNI Plugins Overview](https://www.cni.dev/plugins/current/)
- [Istio Documentation](https://istio.io/latest/docs/)
- [Linkerd Documentation](https://linkerd.io/2/docs/)
- [Kubernetes Networking Recipes](https://github.com/ahmetb/kubernetes-networking-recipes)

## Hands-on Exercises

### Exercise 1: Service Types Deep Dive
1. Create and test all four service types
2. Configure ExternalName services for external dependencies
3. Test NodePort ranges and accessibility
4. Experiment with LoadBalancer in cloud vs local
5. Configure externalIPs for services

### Exercise 2: Service Discovery and DNS
1. Explore Kubernetes internal DNS
2. Test service discovery with various tools
3. Configure custom DNS policies
4. Use headless services for StatefulSets
5. Troubleshoot DNS resolution issues

### Exercise 3: Ingress Controllers and Resources
1. Install and configure NGINX Ingress Controller
2. Create Ingress resources for HTTP routing
3. Implement name-based virtual hosting
4. Configure TLS termination at ingress
5. Use annotations for advanced ingress features

### Exercise 4: Network Policies
1. Create default deny network policies
2. Allow specific namespace communication
3. Control pod-to-pod communication with labels
4. Implement ingress and egress rules
5. Test network policy effectiveness

### Exercise 5: Advanced Networking Concepts
1. Configure external traffic policies
2. Implement session affinity
3. Use headless services for StatefulSets
4. Experiment with CNI plugins
5. Basic service mesh concepts with Istio

## Solutions

<details>
<summary>Exercise 1 Solutions: Service Types Deep Dive</summary>

```bash
# 1. Create and test all four service types
echo "Creating deployment for service testing..."
kubectl create deployment webapp --image=nginx:alpine --port=80

# ClusterIP (default)
echo "Creating ClusterIP service..."
kubectl expose deployment webapp --name=web-clusterip --port=80 --type=ClusterIP
CLUSTER_IP=$(kubectl get svc web-clusterip -o jsonpath='{.spec.clusterIP}')
echo "ClusterIP: $CLUSTER_IP"

# NodePort
echo "Creating NodePort service..."
kubectl expose deployment webapp --name=web-nodeport --port=80 --type=NodePort
NODE_PORT=$(kubectl get svc web-nodeport -o jsonpath='{.spec.ports[0].nodePort}')
echo "NodePort: $NODE_PORT"

# LoadBalancer
echo "Creating LoadBalancer service..."
kubectl expose deployment webapp --name=web-loadbalancer --port=80 --type=LoadBalancer
# Note: In local clusters (minikube/kind), this will show <pending>
# Use minikube service web-loadbalancer --url to get URL

# ExternalName
echo "Creating ExternalName service..."
kubectl create service externalname web-externalname \
  --external-name=www.google.com \
  --tcp=80:80

# 2. Configure ExternalName services for external dependencies
echo "Testing ExternalName service..."
kubectl get svc web-externalname -o yaml
# Test resolution (from within cluster)
kubectl run -it --rm dns-test --image=alpine:latest -- nslookup web-externalname
# Should resolve to www.google.com

# 3. Test NodePort ranges and accessibility
echo "Checking NodePort range..."
kubectl get svc web-nodeport -o jsonpath='{.spec.ports[0].nodePort}'
# Should be in range 30000-32767 by default

# Test accessibility
MINIKUBE_IP=$(minikube ip)
echo "Access NodePort service at: http://$MINIKUBE_IP:$NODE_PORT"
# curl http://$MINIKUBE_IP:$NODE_PORT

# 4. Experiment with LoadBalancer in cloud vs local
echo "LoadBalancer behavior in different environments:"
echo "- Cloud providers: Creates actual load balancer"
echo "- Local (minikube/kind): Shows <pending>, use service command"
echo "- Bare metal: Requires LB implementation (MetalLB, etc.)"

# 5. Configure externalIPs for services
echo "Creating service with externalIPs..."
cat > service-with-externalip.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: web-externalip
spec:
  selector:
    app: webapp
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  externalIPs:
  - 203.0.113.1
  - 203.0.113.2
  type: ClusterIP
EOF

kubectl apply -f service-with-externalip.yaml
kubectl get svc web-externalip -o yaml

# Cleanup
kubectl delete deployment webapp
kubectl delete service web-clusterip web-nodeport web-loadbalancer web-externalname web-externalip
```
</details>

<details>
<summary>Exercise 2 Solutions: Service Discovery and DNS</summary>

```bash
# 1. Explore Kubernetes internal DNS
echo "Exploring Kubernetes DNS..."
# Check CoreDNS deployment
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl get pods -n kube-system -l k8s-app=coreDNS

# Check DNS configuration in pods
kubectl run -it --rm dns-explorer --image=alpine:latest -- sh -c "
  apk add --no-cache bind-tools
  echo '=== Resolv.conf ===' && cat /etc/resolv.conf
  echo '=== Kubernetes service ===' && nslookup kubernetes.default
  echo '=== Default namespace service ===' && nslookup kubernetes
  echo '=== Internal domain ===' && nslookup kubernetes.default.svc.cluster.local
"

# 2. Test service discovery with various tools
echo "Creating test services for discovery..."
kubectl create deployment frontend --image=nginx:alpine
kubectl expose deployment frontend --port=80

kubectl create deployment backend --image=redis:alpine
kubectl expose deployment backend --port=6379

# Test various discovery methods
kubectl run -it --rm discovery-test --image=appropriate/curl -- sh -c "
  echo 'Testing frontend service:'
  curl -s http://frontend:80 | head -5
  echo 'Testing backend service:'
  redis-cli -h backend ping
"

# 3. Configure custom DNS policies
echo "Testing DNS policies..."
cat > custom-dns-pod.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: custom-dns
spec:
  dnsPolicy: None  # Don't use cluster DNS
  dnsConfig:
    nameservers:
    - 8.8.8.8
    - 8.8.4.4
    searches:
    - mydns.svc.cluster.local
    - mydns.svc.cluster.local
    options:
    - name: ndots
      value: "2"
    - name: edns0
  containers:
  - name: test
    image: alpine:latest
    command: ["/bin/sh", "-c", "sleep 3600"]
EOF

kubectl apply -f custom-dns-pod.yaml
kubectl exec custom-dns -- cat /etc/resolv.conf
kubectl exec custom-dns -- nslookup google.com

# 4. Use headless services for StatefulSets
echo "Creating headless service for StatefulSet..."
cat > headless-service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: web-headless
  labels:
    app: web
spec:
  clusterIP: None
  selector:
    app: web
  ports:
  - port: 80
    name: http
EOF

kubectl apply -f headless-service.yaml

# Create StatefulSet using headless service
cat > web-statefulset.yaml << 'EOF'
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  serviceName: "web-headless"
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: web
        image: nginx:alpine
        ports:
        - containerPort: 80
        name: web
EOF

kubectl apply -f web-statefulset.yaml
kubectl get statefulset web
kubectl get pods -l app=web

# Test DNS for StatefulSet
kubectl run -it --rm stateful-dns-test --image=alpine:latest -- sh -c "
  apk add --no-cache bind-tools
  echo '=== Headless service DNS ===' && nslookup web-headless
  echo '=== Individual pod DNS ===' && nslookup web-0.web-headless
  echo '=== Another pod DNS ===' && nslookup web-1.web-headless
"

# 5. Troubleshoot DNS resolution issues
echo "DNS troubleshooting commands:"
echo "kubectl get pods -n kube-system -l k8s-app=kube-dns"
echo "kubectl logs -n kube-system -l k8s-app=kube-dns"
echo "kubectl run -it --rm dns-debug --image=appropriate/curl -- nslookup kubernetes.default"
echo "kubectl get svc -n kube-system kube-dns -o yaml"

# Cleanup
kubectl delete -f custom-dns-pod.yaml headless-service.yaml web-statefulset.yaml
kubectl delete deployment frontend backend
kubectl delete service frontend backend
kubectl delete pod dns-explorer discovery-test stateful-dns-test dns-test --ignore-not-found
```
</details>

<details>
<summary>Exercise 3 Solutions: Ingress Controllers and Resources</summary>

```bash
# 1. Install and configure NGINX Ingress Controller
echo "Installing NGINX Ingress Controller..."
# Using Helm (recommended method)
# helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
# helm repo update
# helm install ingress-nginx ingress-nginx/ingress-nginx

# Alternative: Manual installation with manifests
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.0/deploy/static/provider/cloud/deploy.yaml

# Wait for ingress controller to be ready
echo "Waiting for ingress controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=ingress-nginx \
  --timeout=120s

# 2. Create Ingress resources for HTTP routing
echo "Creating sample applications for ingress..."
kubectl create deployment web1 --image=nginx:alpine --port=80
kubectl create deployment web2 --image=httpd:alpine --port=80

# Expose deployments via ClusterIP services (required for ingress)
kubectl expose deployment web1 --port=80
kubectl expose deployment web2 --port=80

# Create simple ingress
cat > simple-ingress.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: simple-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web1
            port:
              number: 80
EOF

kubectl apply -f simple-ingress.yaml
kubectl get ingress simple-ingress

# 3. Implement name-based virtual hosting
echo "Creating name-based virtual hosting..."
cat > virtual-hosting-ingress.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: virtual-hosting
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  ingressClassName: nginx
  rules:
  - host: web1.example.com
    http:
      paths:
      - path: /(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: web1
            port:
              number: 80
  - host: web2.example.com
    http:
      paths:
      - path: /(|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: web2
            port:
              number: 80
EOF

kubectl apply -f virtual-hosting-ingress.yaml
kubectl get ingress virtual-hosting

# 4. Configure TLS termination at ingress
echo "Creating TLS secret and configuring TLS termination..."
# Create self-signed certificate for testing
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt -subj "/CN=example.com/O=example.com"

# Create TLS secret
kubectl create secret tls example-tls --key=tls.key --cert=tls.crt

# Update ingress with TLS
cat > tls-ingress.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tls-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - example.com
    secretName: example-tls
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web1
            port:
              number: 80
EOF

kubectl apply -f tls-ingress.yaml
kubectl get ingress tls-ingress

# 5. Use annotations for advanced ingress features
echo "Testing advanced ingress annotations..."
cat > advanced-ingress.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: advanced-ingress
  annotations:
    # Rate limiting
    nginx.ingress.kubernetes.io/limit-rpm: "100"
    # Custom error pages
    nginx.ingress.kubernetes.io/custom-html-errors: "500|502|503|504= /usr/share/nginx/html/50x.html"
    # Upload size limit
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"
    # Enable gzip compression
    nginx.ingress.kubernetes.io/enable-gzip: "true"
    # Proxy buffer size
    nginx.ingress.kubernetes.io/proxy-buffer-size: "8k"
    # Custom HTTP headers
    nginx.ingress.kubernetes.io/configuration-snippet: |
      more_set_headers 'X-Custom-Header: devops-value';
spec:
  ingressClassName: nginx
  rules:
  - host: advanced.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web1
            port:
              number: 80
EOF

kubectl apply -f advanced-ingress.yaml
kubectl get ingress advanced-ingress -o yaml | grep annotations

# Cleanup
kubectl delete -f simple-ingress.yaml virtual-hosting-ingress.yaml tls-ingress.yaml advanced-ingress.yaml
kubectl delete deployment web1 web2
kubectl delete service web1 web2
kubectl delete secret example-tls
rm tls.key tls.crt
```
</details>

<details>
<summary>Exercise 4 Solutions: Network Policies</summary>

```bash
# 1. Create default deny network policies
echo "Creating default deny network policy..."
cat > default-deny.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
spec:
  podSelector: {}  # Selects all pods in namespace
  policyTypes:
  - Ingress
  - Egress
EOF

kubectl apply -f default-deny.yaml
kubectl get networkpolicy default-deny

# 2. Allow specific namespace communication
echo "Creating namespaces and allowing communication..."
kubectl create namespace frontend
kubectl create namespace backend
kubectl create namespace database

# Deploy applications in each namespace
kubectl create deployment frontend-app --image=nginx:alpine -n frontend
kubectl expose deployment frontend-app --port=80 -n frontend

kubectl create deployment backend-app --image=redis:alpine -n backend
kubectl expose deployment backend-app --port=6379 -n backend

kubectl create deployment db-app --image=postgres:alpine -n database
kubectl expose deployment db-app --port=5432 -n database

# Allow frontend to backend communication
cat > allow-frontend-to-backend.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: backend-app
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: frontend
    - podSelector:
        matchLabels:
          app: frontend-app
  ports:
  - protocol: TCP
    port: 6379
  policyTypes:
  - Ingress
EOF

kubectl apply -f allow-frontend-to-backend.yaml -n backend

# Allow backend to database communication
cat > allow-backend-to-database.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backend-to-database
  namespace: database
spec:
  podSelector:
    matchLabels:
      app: db-app
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: backend
    - podSelector:
        matchLabels:
          app: backend-app
  ports:
  - protocol: TCP
    port: 5432
  policyTypes:
  - Ingress
EOF

kubectl apply -f allow-backend-to-database.yaml -n database

# 3. Control pod-to-pod communication with labels
echo "Creating label-based network policies..."
# Label existing pods
kubectl label pod -l app=frontend-app tier=frontend -n frontend
kubectl label pod -l app=backend-app tier=backend -n backend
kubectl label pod -l app=db-app tier=database -n database

# Allow only frontend tier to communicate with backend tier
cat > tier-based-policy.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-tier-to-backend-tier
  namespace: backend
spec:
  podSelector:
    matchLabels:
      tier: backend
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: frontend
    namespaceSelector:
      matchLabels:
        kubernetes.io/metadata.name: frontend
  ports:
  - protocol: TCP
    port: 6379
  policyTypes:
  - Ingress
EOF

kubectl apply -f tier-based-policy.yaml -n backend

# 4. Implement ingress and egress rules
echo "Creating comprehensive network policy with ingress/egress..."
cat > comprehensive-network-policy.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: web-policy
  namespace: frontend
spec:
  podSelector:
    matchLabels:
      app: frontend-app
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - ipBlock:
        cidr: 10.0.0.0/8
        except:
        - 10.1.2.0/24
    - namespaceSelector:
        matchLabels:
          project: myproject
    - podSelector:
        matchLabels:
          role: frontend
  ports:
  - protocol: TCP
    port: 80
  egress:
  - to:
    - ipBlock:
        cidr: 10.0.0.0/8
    ports:
    - protocol: TCP
      port: 53  # DNS
    - protocol: UDP
      port: 53  # DNS
  - to:
    - ipBlock:
        cidr: 10.0.0.0/8
    ports:
    - protocol: TCP
      port: 443  # HTTPS
      port: 80   # HTTP
EOF

kubectl apply -f comprehensive-network-policy.yaml -n frontend

# 5. Test network policy effectiveness
echo "Testing network policy effectiveness..."
# Create test pods to verify policies
kubectl run -it --rm test-access --image=appropriate/curl -n frontend -- sh -c "
  echo 'Testing access to backend service...'
  curl -s -m 5 http://backend-app.backend.svc.cluster.local:6379 || echo 'Connection failed or timed out (expected if policy blocks)'
  echo 'Testing DNS resolution...'
  nslookup backend-app.backend.svc.cluster.local
"

# Cleanup
kubectl delete namespace frontend backend database
kubectl delete networkpolicy default-deny allow-frontend-to-backend allow-backend-to-database tier-based-policy comprehensive-network-policy --ignore-not-found
kubectl delete all --all
```
</details>

<details>
<summary>Exercise 5 Solutions: Advanced Networking Concepts</summary>

```bash
# 1. Configure external traffic policies
echo "Testing external traffic policies..."
kubectl create deployment webapp --image=nginx:alpine
kubectl expose deployment webapp --name=web-service --port=80 --type=NodePort

# Local traffic (default)
kubectl patch service web-service -p '{"spec":{"externalTrafficPolicy":"Local"}}'
kubectl get service web-service -o yaml | grep externalTrafficPolicy

# Cluster traffic
kubectl patch service web-service -p '{"spec":{"externalTrafficPolicy":"Cluster"}}'
kubectl get service web-service -o yaml | grep externalTrafficPolicy

# 2. Implement session affinity
echo "Testing session affinity (sticky sessions)..."
kubectl patch service web-service -p '{"spec":{"sessionAffinity":"ClientIP"}}'
kubectl get service web-service -o yaml | grep sessionAffinity

# ClientIP based affinity
kubectl patch service web-service -p '{"spec":{"sessionAffinity":"ClientIP"}}'
kubectl get service web-service -o yaml | grep sessionAffinity

# None (no affinity)
kubectl patch service web-service -p '{"spec":{"sessionAffinity":"None"}}'
kubectl get service web-service -o yaml | grep sessionAffinity

# 3. Use headless services for StatefulSets
echo "Creating headless service for StatefulSet (review from Exercise 2)..."
cat > kafka-headless.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: kafka-headless
  labels:
    app: kafka
spec:
  clusterIP: None
  selector:
    app: kafka
  ports:
  - port: 9092
    name: kafka
EOF

kubectl apply -f kafka-headless.yaml

# Create StatefulSet for Kafka-like application
cat > kafka-statefulset.yaml << 'EOF'
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: kafka
spec:
  serviceName: "kafka-headless"
  replicas: 3
  selector:
    matchLabels:
      app: kafka
  template:
    metadata:
      labels:
        app: kafka
    spec:
      containers:
      - name: kafka
        image: confluentinc/cp-kafka:latest
        ports:
        - containerPort: 9092
        name: kafka
        env:
        - name: KAFKA_BROKER_ID
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: KAFKA_ZOOKEEPER_CONNECT
          value: "zookeeper:2181"
        - name: KAFKA_ADVERTISED_LISTENERS
          value: PLAINTEXT://$(HOSTNAME).kafka-headless:9092
EOF

# 4. Experiment with CNI plugins
echo "Checking current CNI plugin..."
kubectl get nodes -o jsonpath='{.items[0].metadata.annotations.kubernetes\\.io/config\\.see}'
# Or check CNI config directory
# ls -la /etc/cni/net.d/

# Common CNI plugins:
echo "Common CNI plugins:"
echo "- Flannel: Simple overlay network"
echo "- Calico: Network policy focused"
echo "- Weave Net: Encrypted overlay"
echo "- Canal: Flannel + Calico"
echo "- Cilium: eBPF-based networking"

# 5. Basic service mesh concepts with Istio
echo "Introduction to service mesh concepts..."
echo "Service mesh provides:"
echo "- Traffic management (routing, retries, timeouts)"
echo "- Security (mTLS, authorization, authentication)"
echo "- Observability (metrics, logs, tracing)"
echo ""
echo "Popular service meshes:"
echo "- Istio: Feature-rich, complex"
echo "- Linkerd: Simple, lightweight"
echo "- Consul Connect: HashiCorp ecosystem"
echo "- AWS App Mesh: AWS-native"
echo ""
echo "Basic Istio concepts:"
echo "- Envoy proxy sidecar"
echo "- Control plane (Pilot, Citadel, Galley)"
echo "- VirtualService, DestinationRule, Gateway"
echo "- PeerAuthorization, RequestAuthorization"

# Cleanup
kubectl delete deployment webapp
kubectl delete service web-service
kubectl delete -f kafka-headless.yaml kafka-statefulset.yaml
kubectl delete all --all
```
</details>