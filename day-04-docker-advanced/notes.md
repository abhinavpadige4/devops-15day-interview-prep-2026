# Day 4: Docker Advanced & Networking

## Topics Covered
- Docker networking models (bridge, host, overlay, macvlan, none)
- Custom network creation and management
- Container communication and service discovery
- Port publishing and binding
- Docker Compose in depth
- Multi-container applications
- Environment variables and configuration
- Docker secrets and configs
- Health checks and restart policies
- Resource constraints (CPU, memory, disk)
- Logging drivers and log management
- Private registry setup and usage
- Image scanning and security

## Resources
- [Docker Networking Deep Dive](https://docs.docker.com/network/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [Docker Engine API](https://docs.docker.com/engine/api/)
- [Docker Registry Documentation](https://docs.docker.com/registry/)
- [Docker Bench for Security](https://github.com/docker/docker-bench-security)
- [Play with Docker Networking Labs](https://labs.play-with-docker.com/)

## Hands-on Exercises

### Exercise 1: Docker Networking Deep Dive
1. Explore default bridge network
2. Create custom bridge networks
3. Connect containers to custom networks
4. Test inter-container communication
5. Configure network aliases and DNS
6. Experiment with host and none networks

### Exercise 2: Docker Compose Applications
1. Create docker-compose.yml for multi-service app
2. Define services, networks, and volumes
3. Use environment variables and configs
4. Scale services with docker-compose
5. Use depends_on for service dependencies
6. Apply profiles for environment-specific configs

### Exercise 3: Advanced Container Configuration
1. Set resource limits (CPU, memory)
2. Configure restart policies
3. Implement health checks
4. Use Docker secrets for sensitive data
5. Configure logging drivers
6. Apply security options (read-only rootfs, drop capabilities)

### Exercise 4: Private Registry and Image Management
1. Set up local Docker registry
2. Push and pull images from private registry
3. Implement basic authentication
4. Use self-signed certificates
5. Implement image garbage collection
6. Scan images for vulnerabilities

### Exercise 5: Docker Optimization and Troubleshooting
1. Analyze image layers and size
2. Optimize Dockerfile for build cache
3. Troubleshoot container startup issues
4. Debug networking problems
5. Monitor container performance
6. Clean up unused Docker objects

## Solutions

<details>
<summary>Exercise 1 Solutions: Docker Networking Deep Dive</summary>

```bash
# 1. Explore default bridge network
echo "Exploring default bridge network..."
docker network ls
docker network inspect bridge

# 2. Create custom bridge networks
echo "Creating custom bridge networks..."
docker network create --driver bridge --subnet 172.20.0.0/16 --gateway 172.20.0.1 custom-net
docker network create --driver bridge --subnet 172.21.0.0/16 --gateway 172.21.0.1 isolated-net

# 3. Connect containers to custom networks
echo "Connecting containers to custom networks..."
docker run -d --name web1 --net custom-net nginx:latest
docker run -d --name db1 --net custom-net -e POSTGRES_PASSWORD=secret postgres:alpine
docker run -d --name cache1 --net isolated-net redis:alpine

# 4. Test inter-container communication
echo "Testing inter-container communication..."
docker exec web1 ping -c 3 db1
docker exec web1 getent hosts db1
docker exec db1 ping -c 3 web1

# Test that isolated network containers can't communicate with custom-net
docker exec cache1 ping -c 3 web1 2>/dev/null || echo "Expected: isolated network cannot reach custom-net"

# 5. Configure network aliases and DNS
echo "Testing network aliases and DNS..."
docker network connect --alias web-service custom-net web1
docker exec db1 getent hosts web-service
docker exec db1 ping -c 2 web-service

# 6. Experiment with host and none networks
echo "Testing host network..."
docker run -d --name host-nginx --net host nginx:latest
# Note: Host network shares host's network stack

echo "Testing none network..."
docker run -d --name none-nginx --net none nginx:latest
# Note: None network has no network interfaces except lo
docker exec none-nginx ip addr show  # Should show only loopback

# Cleanup
docker stop web1 db1 cache1 host-nginx none-nginx
docker rm web1 db1 cache1 host-nginx none-nginx
docker network rm custom-net isolated-net
```
</details>

<details>
<summary>Exercise 2 Solutions: Docker Compose Applications</summary>

```bash
# 1. Create docker-compose.yml for multi-service app
echo "Creating docker-compose.yml for blog application..."
mkdir -p blog-app
cd blog-app

cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./html:/usr/share/nginx/html
      - ./nginx.conf:/etc/nginx/conf.d/default.conf
    depends_on:
      - api
    networks:
      - frontend
      - backend

  api:
    build: ./api
    ports:
      - "5000:5000"
    environment:
      - DATABASE_URL=postgresql://user:password@db:5432/blog
      - REDIS_URL=redis://cache:6379
    volumes:
      - ./api/code:/app
    networks:
      - backend
    deploy:
      resources:
        limits:
          cpus: "0.5"
          memory: 256M
        reservations:
          cpus: "0.25"
          memory: 128M

  db:
    image: postgres:13-alpine
    environment:
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=blog
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - backend

  cache:
    image: redis:alpine
    networks:
      - backend

volumes:
  db-data:

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
EOF

# Create supporting directories and files
mkdir -p html api nginx.conf

echo "<h1>Hello from Docker Compose!</h1>" > html/index.html

cat > nginx.conf/default.conf << 'EOF'
server {
    listen 80;
    location / {
        proxy_pass http://api:5000;
    }
    location /static/ {
        alias /usr/share/nginx/html/;
    }
}
EOF

mkdir -p api/code
cat > api/code/app.py << 'EOF'
from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route('/')
def hello():
    return jsonify({"message": "Hello from API!", "status": "running"})

@app.route('/health')
def health():
    return jsonify({"status": "healthy"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

cat > api/Dockerfile << 'EOF'
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY code/ .
EXPOSE 5000
CMD ["python", "app.py"]
EOF

cat > api/requirements.txt << 'EOF'
flask==2.3.2
EOF

# 2. Define services, networks, and volumes
echo "Services defined:"
echo "- web: Nginx reverse proxy"
echo "- api: Flask application"
echo "- db: PostgreSQL database"
echo "- cache: Redis cache"
echo ""
echo "Networks:"
echo "- frontend: Exposes web service"
echo "- backend: Internal services communication"
echo ""
echo "Volumes:"
echo "- db-data: Persistent database storage"

# 3. Use environment variables and configs
echo "Environment variables configured:"
echo "- DATABASE_URL: Database connection string"
echo "- REDIS_URL: Redis connection string"
echo ""
echo "To override in docker-compose.override.yml:"
cat > docker-compose.override.yml << 'EOF'
version: '3.8'
services:
  web:
    environment:
      - NGINX_PORT=8080
  api:
    environment:
      - DEBUG=true
      - LOG_LEVEL=info
EOF

# 4. Scale services with docker-compose
echo "To scale services:"
echo "docker-compose up -d --scale api=3"
echo "docker-compose ps"

# 5. Use depends_on for service dependencies
echo "Depends_on ensures startup order:"
echo "web depends on api"
echo "api depends on db and cache (implicitly through env vars)"

# 6. Apply profiles for environment-specific configs
echo "Creating profile-specific configuration..."
cat > docker-compose.prod.yml << 'EOF'
version: '3.8'
services:
  web:
    image: nginx:stable-alpine
    deploy:
      replicas: 2
  api:
    image: mycompany/blog-api:prod
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: "1.0"
          memory: 512M
EOF

# To use profiles:
echo "docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d"

# Cleanup
cd ..
rm -rf blog-app
```
</details>

<details>
<summary>Exercise 3 Solutions: Advanced Container Configuration</summary>

```bash
# 1. Set resource limits (CPU, memory)
echo "Setting resource limits..."
docker run -d --name limited-app \
  --cpus="0.5" \
  --memory="256M" \
  nginx:latest

# Verify limits
docker inspect limited-app --format='{{.HostConfig.CpuQuota}}'
docker inspect limited-app --format='{{.HostConfig.Memory}}'

# 2. Configure restart policies
echo "Testing restart policies..."
docker run -d --name always-restart \
  --restart always \
  alpine:latest \
  sh -c "echo 'Container started at $(date)' >> /tmp/start.log && sleep 30"

docker run -d --name on-failure \
  --restart on-failure:3 \
  alpine:latest \
  sh -c "exit 1"  # This will fail and restart up to 3 times

docker run -d --name unless-stopped \
  --restart unless-stopped \
  nginx:latest

# 3. Implement health checks
echo "Adding health check to container..."
docker run -d --name healthcheck-web \
  --health-cmd="curl -f http://localhost:80 || exit 1" \
  --health-interval=30s \
  --health-timeout=10s \
  --health-retries=3 \
  --health-start-period=40s \
  nginx:latest

# Check health status
docker inspect healthcheck-web --format='{{json .State.Health}}'

# 4. Use Docker secrets for sensitive data
echo "Setting up Docker secrets (requires swarm mode)..."
# Initialize swarm (if not already)
docker swarm init 2>/dev/null || echo "Swarm already initialized"

# Create secret
echo "supersecretpassword" | docker secret create db_password -

# Create service using secret
docker service create \
  --name db-service \
  --secret db_password \
  postgres:alpine

# 5. Configure logging drivers
echo "Testing different logging drivers..."
docker run -d --name json-log-test \
  --log-driver=json-file \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  nginx:latest

docker run -d --name syslog-test \
  --log-driver=syslog \
  --log-opt syslog-address=udp://127.0.0.1:514 \
  nginx:latest

# View logs
docker logs json-log-test
docker logs syslog-test

# 6. Apply security options
echo "Applying security options..."
docker run -d --name secure-nginx \
  --read-only \
  --tmpfs /tmp \
  --tmpfs /var/run \
  --tmpfs /var/cache/nginx \
  --cap-drop ALL \
  --cap-add NET_BIND_SERVICE \
  nginx:latest

# Verify security settings
docker inspect secure-nginx --format='{{.HostConfig.ReadonlyRootfs}}'
docker inspect secure-nginx --format='{{.HostConfig.CapDrop}}'
docker inspect secure-nginx --format='{{.HostConfig.CapAdd}}'

# Cleanup
docker stop limited-app always-restart on-failure unless-stopped healthcheck-web json-log-test syslog-test secure-nginx
docker rm limited-app always-restart on-failure unless-stopped healthcheck-web json-log-test syslog-test secure-nginx
docker secret rm db_password 2>/dev/null || echo "No secret to remove"
docker swarm leave --force 2>/dev/null || echo "Not in swarm or already left"
```
</details>

<details>
<summary>Exercise 4 Solutions: Private Registry and Image Management</summary>

```bash
# 1. Set up local Docker registry
echo "Setting up local Docker registry..."
docker run -d -p 5000:5000 --restart=always --name registry \
  -v $(pwd)/registry-data:/var/lib/registry \
  registry:2

# Wait for registry to start
sleep 5
echo "Registry running at localhost:5000"

# 2. Push and pull images from private registry
echo "Preparing image for private registry..."
docker pull nginx:latest
docker tag nginx:latest localhost:5000/nginx:latest
docker tag nginx:latest localhost:5000/nginx:v1.0

echo "Pushing images to private registry..."
docker push localhost:5000/nginx:latest
docker push localhost:5000/nginx:v1.0

echo "Pulling images from private registry..."
docker pull localhost:5000/nginx:latest
docker run -d --name registry-nginx -p 8082:80 localhost:5000/nginx:latest

# 3. Implement basic authentication
echo "Setting up basic authentication for registry..."
mkdir -p auth
docker run --rm \
  --entrypoint htpasswd \
  httpd:2 -Bbn testuser testpassword > auth/htpasswd

# Stop and remove current registry
docker stop registry
docker rm registry

# Start registry with authentication
docker run -d -p 5000:5000 --restart=always --name registry \
  -v $(pwd)/registry-data:/var/lib/registry \
  -v $(pwd)/auth:/auth \
  -e "REGISTRY_AUTH=htpasswd" \
  -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
  -e "REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd" \
  registry:2

# Login to registry
echo "Logging in to private registry..."
docker login localhost:5000
# Username: testuser
# Password: testpassword

# Push authenticated images
docker tag nginx:latest localhost:5000/nginx:auth-latest
docker push localhost:5000/nginx:auth-latest

# 4. Use self-signed certificates
echo "Setting up TLS with self-signed certificates..."
mkdir -p certs
openssl req -newkey rsa:4096 -nodes -sha256 -keyout certs/domain.key \
  -x509 -days 365 -out certs/domain.crt -subj "/CN=localhost"

# Stop registry
docker stop registry
docker rm registry

# Start registry with TLS
docker run -d -p 5000:5000 --restart=always --name registry \
  -v $(pwd)/registry-data:/var/lib/registry \
  -v $(pwd)/certs:/certs \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
  registry:2

# Configure Docker daemon to trust self-signed cert
# Add to /etc/docker/daemon.json:
# {
#   "insecure-registries" : ["localhost:5000"]
# }
# Then restart Docker: sudo systemctl restart docker

# 5. Implement image garbage collection
echo "Running registry garbage collection..."
docker exec registry bin/registry garbage-collect /etc/docker/registry/config.yml

# 6. Scan images for vulnerabilities
echo "Scanning images for vulnerabilities (using Trivy)..."
# Install Trivy if not present
if ! command -v trivy &> /dev/null; then
    echo "Installing Trivy..."
    # Ubuntu/Debian
    sudo apt-get install -y wget apt-transport-https gnupg lsb-release
    wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
    echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list
    sudo apt-get update
    sudo apt-get install -y trivy
fi

# Scan local image
trivy image nginx:latest

# Scan image in private registry
trivy image localhost:5000/nginx:latest

# Cleanup
docker stop registry
docker rm registry
sudo rm -rf registry-data auth certs
```
</details>

<details>
<summary>Exercise 5 Solutions: Docker Optimization and Troubleshooting</summary>

```bash
# 1. Analyze image layers and size
echo "Analyzing image layers and size..."
docker images nginx:latest --format "{{.Repository}}:{{.Tag}}\t{{.Size}}"

# Detailed layer analysis
docker history nginx:latest

# Image content analysis
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  wagoodman/dive:latest nginx:latest

# 2. Optimize Dockerfile for build cache
echo "Creating optimized Dockerfile examples..."
cat > Dockerfile.bad << 'EOF'
# BAD: Order causes cache invalidation
FROM node:16
COPY . .  # This invalidates cache whenever ANY file changes
RUN npm ci
EXPOSE 3000
CMD ["node", "index.js"]
EOF

cat > Dockerfile.good << 'EOF'
# GOOD: Leverage build cache
FROM node:16
WORKDIR /app
COPY package*.json .  # Only copy package files first
RUN npm ci            # Dependencies layer - changes only when package files change
COPY . .              # Copy source code - changes frequently
EXPOSE 3000
CMD ["node", "index.js"]
EOF

# 3. Troubleshoot container startup issues
echo "Troubleshooting container startup..."
# Common issues and diagnostics

# Check container logs
docker run --name test-fail --rm alpine:latest sh -c "exit 1"
docker logs test-fail

# Inspect container state
docker run --name test-inspect -d nginx:latest
docker inspect test-inspect --format='{{json .State}}'
docker stop test-inspect
docker rm test-inspect

# Check exit codes
docker run --rm alpine:latest sh -c "echo 'Hello World'; exit 0"
echo "Exit code: $?"

docker run --rm alpine:latest sh -c "false"
echo "Exit code: $?"

# 4. Debug networking problems
echo "Debugging networking..."
# Create test network
docker network create test-net

# Run containers for testing
docker run -d --name net-test1 --net test-net alpine:latest sleep 300
docker run -d --name net-test2 --net test-net alpine:latest sleep 300

# Test connectivity
docker exec net-test1 ping -c 3 net-test2
docker exec net-test1 nslookup net-test2

# Check network configuration
docker inspect net-test1 --format='{{json .NetworkSettings.Networks.test-net}}'

# Cleanup
docker stop net-test1 net-test2
docker rm net-test1 net-test2
docker network rm test-net

# 5. Monitor container performance
echo "Monitoring container performance..."
docker run -d --name perf-test --cpus="0.5" --memory="128M" nginx:latest

# Basic stats
docker stats perf-test --no-stream

# Detailed stats
docker stats perf-test --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"

# cgroup information
CONTAINER_ID=$(docker ps -qf "name=perf-test")
echo "Cgroup path: /sys/fs/cgroup/system/docker/${CONTAINER_ID}.slice"
ls -la /sys/fs/cgroup/system/docker/${CONTAINER_ID}.slice/

# 6. Clean up unused Docker objects
echo "Cleaning up unused Docker objects..."
# Show what would be removed
docker system prune -a --dry-run

# Actually clean (use with caution!)
# docker system prune -a -f
# docker volume prune -f
# docker network prune -f

# Cleanup test container
docker stop perf-test
docker rm perf-test
```
</details>