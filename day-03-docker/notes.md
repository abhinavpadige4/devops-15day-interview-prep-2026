# Day 3: Docker Basics

## Topics Covered
- Containerization vs Virtualization
- Docker architecture (daemon, client, registry)
- Images vs Containers
- Dockerfile basics and best practices
- Basic Docker commands (run, ps, images, pull, push)
- Container lifecycle management
- Volumes and data persistence
- Networking basics (bridge, host, none networks)
- Docker Compose introduction
- Container logging and monitoring

## Resources
- [Play with Docker - Official Docker Playground](https://labs.play-with-docker.com/)
- [Docker Get Started Tutorial](https://docs.docker.com/get-started/)
- [Dockerfile Reference](https://docs.docker.com/engine/reference/builder/)
- [Docker Networking Documentation](https://docs.docker.com/network/)
- [Docker Volumes Documentation](https://docs.docker.com/storage/volumes/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Katacoda Docker Scenarios](https://www.katacoda.com/courses/docker)

## Hands-on Exercises

### Exercise 1: Docker Installation and Hello World
1. Install Docker Engine on your system
2. Verify installation with `docker version` and `docker info`
3. Run the hello-world container
4. List Docker images and containers
5. Remove the hello-world container

### Exercise 2: Working with Docker Images
1. Pull various images from Docker Hub (nginx, ubuntu, alpine)
2. List and inspect images
3. Tag images with custom tags
4. Remove unused images
5. Search for images on Docker Hub

### Exercise 3: Running and Managing Containers
1. Run containers in detached and interactive modes
2. Execute commands inside running containers
3. Start, stop, and restart containers
4. View container logs
5. Inspect container details
6. Remove containers

### Exercise 4: Dockerfile Creation and Image Building
1. Create a simple Dockerfile for a web application
2. Build custom images using Dockerfile
3. Tag and push images to a registry
4. Use .dockerignore file
5. Optimize Dockerfile layers

### Exercise 5: Data Persistence with Volumes
1. Create and manage Docker volumes
2. Mount host directories as volumes
3. Share data between containers using volumes
4. Backup and restore volume data
5. Use volume drivers

## Solutions

<details>
<summary>Exercise 1 Solutions: Docker Installation and Hello World</summary>

```bash
# 1. Install Docker Engine
# Ubuntu/Debian method
echo "Installing Docker Engine..."
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y docker-ce

# Start and enable Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add current user to docker group (optional but recommended)
sudo usermod -aG docker $USER
# Note: You'll need to log out and back in for this to take effect

# 2. Verify installation
echo "Verifying Docker installation..."
docker version
docker info

# 3. Run the hello-world container
echo "Running hello-world container..."
docker run hello-world

# 4. List Docker images and containers
echo "Listing Docker images..."
docker images

echo "Listing all containers (including stopped)..."
docker ps -a

# 5. Remove the hello-world container
echo "Cleaning up..."
docker rm $(docker ps -aqf "name=hello-world") 2>/dev/null || echo "No hello-world containers to remove"
docker rmi hello-world 2>/dev/null || echo "No hello-world image to remove"
```
</details>

<details>
<summary>Exercise 2 Solutions: Working with Docker Images</summary>

```bash
# 1. Pull various images from Docker Hub
echo "Pulling Docker images..."
docker pull nginx:latest
docker pull ubuntu:20.04
docker pull alpine:latest
docker pull redis:alpine

# 2. List and inspect images
echo "Listing images..."
docker images

echo "Inspecting nginx image..."
docker inspect nginx:latest

# 3. Tag images with custom tags
echo "Tagging images..."
docker tag nginx:latest my-nginx:v1.0
docker tag nginx:latest my-nginx:latest
docker tag ubuntu:20.04 my-ubuntu:focal

# 4. Remove unused images
echo "Removing unused images..."
# Remove dangling images
docker image prune -f

# Remove specific images
docker rmi my-nginx:v1.0 my-nginx:latest my-ubuntu:focal 2>/dev/null || echo "Some images not found"

# 5. Search for images on Docker Hub
echo "Searching for images..."
docker search nginx
docker search --limit 5 redis
```
</details>

<details>
<summary>Exercise 3 Solutions: Running and Managing Containers</summary>

```bash
# 1. Run containers in detached and interactive modes
echo "Running containers in different modes..."

# Detached mode (background)
echo "Running nginx in detached mode..."
docker run -d --name webserver -p 8080:80 nginx:latest

# Interactive mode
echo "Running Ubuntu container interactively..."
docker run -it --name ubuntu-test ubuntu:20.04 bash
# Inside container: run some commands, then type 'exit' to return to host

# 2. Execute commands inside running containers
echo "Executing commands in running container..."
docker exec webserver nginx -v
docker exec webserver ps aux
docker exec webserver ls -la /var/log/nginx/

# 3. Start, stop, and restart containers
echo "Managing container lifecycle..."
docker stop webserver
docker start webserver
docker restart webserver

# 4. View container logs
echo "Viewing container logs..."
docker logs webserver
docker logs -f webserver  # Follow logs (Ctrl+C to stop)
docker logs --tail 50 webserver  # Last 50 lines

# 5. Inspect container details
echo "Inspecting container details..."
docker inspect webserver
docker inspect --format='{{.State.Status}}' webserver
docker inspect --format='{{.NetworkSettings.IPAddress}}' webserver

# 6. Remove containers
echo "Cleaning up containers..."
docker stop webserver
docker rm webserver

# Force remove running container
# docker rm -f webserver

# Remove all stopped containers
docker container prune -f
```
</details>

<details>
<summary>Exercise 4 Solutions: Dockerfile Creation and Image Building</summary>

```bash
# 1. Create a simple Dockerfile for a web application
echo "Creating Dockerfile for simple web app..."
cat > Dockerfile << 'EOF'
# Use official Python runtime as base image
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Copy requirements file
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Expose port
EXPOSE 8000

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Run application
CMD ["python", "app.py"]
EOF

# Create sample requirements.txt and app.py
cat > requirements.txt << 'EOF'
flask==2.3.2
EOF

cat > app.py << 'EOF'
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    return 'Hello from Dockerized Flask App!'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)
EOF

# 2. Build custom images using Dockerfile
echo "Building Docker image..."
docker build -t my-web-app:latest .
docker build -t my-web-app:v1.0 .

# 3. Tag and push images to a registry
echo "Tagging image for registry..."
docker tag my-web-app:latest username/my-web-app:latest
docker tag my-web-app:v1.0 username/my-web-app:v1.0

# To push to Docker Hub (requires login):
# docker login
# docker push username/my-web-app:latest
# docker push username/my-web-app:v1.0

# 4. Use .dockerignore file
echo "Creating .dockerignore..."
cat > .dockerignore << 'EOF'
__pycache__
*.pyc
*.pyo
*.pyd
.Python
env
build
develop-eggs
dist
downloads
eggs
.eggs
lib
lib64
parts
sdist
var
wheels
share/python-wheels
*.egg-info
.installed.cfg
*.egg
.Python
build
develop-eggs
dist
downloads
eggs
.eggs
lib
lib64
parts
sdist
var
wheels
pip-log.txt
pip-delete-this-directory.txt
.spotlight
.DS_Store
*.potential*.pyc
node_modules
npm-debug.log
EOF

# 5. Optimize Dockerfile layers
echo "Creating optimized Dockerfile..."
cat > Dockerfile.optimized << 'EOF'
# Use multi-stage build for smaller image
FROM python:3.9-slim as builder

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends gcc && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Production stage
FROM python:3.9-slim

WORKDIR /app

# Copy installed packages from builder
COPY --from=builder /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy application code
COPY . .

EXPOSE 8000
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

CMD ["python", "app.py"]
EOF
```
</details>

<details>
<summary>Exercise 5 Solutions: Data Persistence with Volumes</summary>

```bash
# 1. Create and manage Docker volumes
echo "Creating and managing Docker volumes..."

# Create named volume
docker volume create my-app-data

# List volumes
docker volume ls

# Inspect volume
docker volume inspect my-app-data

# 2. Mount host directories as volumes
echo "Mounting host directory as volume..."
mkdir -p /tmp/nginx-conf
echo "server {
    listen 80;
    location / {
        return 200 'Hello from mounted config!';
        add_header Content-Type text/plain;
    }
}" > /tmp/nginx-conf/default.conf

# Run container with mounted volume
docker run -d --name nginx-conf \
  -p 8081:80 \
  -v /tmp/nginx-conf:/etc/nginx/conf.d \
  nginx:latest

# 3. Share data between containers using volumes
echo "Sharing data between containers..."

# Create volume and populate with initial data
docker volume create shared-data
docker run -d --name data-loader \
  -v shared-data:/data \
  alpine:latest \
  sh -c "echo 'Hello from shared volume!' > /data/greeting.txt && sleep 300"

# Wait a moment for data to be written
sleep 2

# Use same volume in another container
docker run --rm \
  -v shared-data:/data \
  alpine:latest \
  cat /data/greeting.txt

# 4. Backup and restore volume data
echo "Backing up volume data..."
# Method 1: Using container to tar volume
docker run --rm \
  -v my-app-data:/data \
  -v $(pwd):/backup \
  alpine:latest \
  tar czf /backup/my-app-data-backup.tar.gz -C /data .

# Method 2: Direct backup (if you know volume path)
VOLUME_PATH=$(docker volume inspect my-app-data --format '{{.Mountpoint}}')
sudo tar czf my-app-data-backup.tar.gz -C $VOLUME_PATH .

echo "Restoring volume data..."
# Create new volume and restore
docker volume create my-app-data-restored
docker run --rm \
  -v my-app-data-restored:/data \
  -v $(pwd):/backup \
  alpine:latest \
  tar xzf /backup/my-app-data-backup.tar.gz -C /data

# 5. Use volume drivers (example with local driver)
echo "Checking volume drivers..."
docker volume ls --format '{{.Driver}}'

# Create volume with specific options (if driver supports it)
# docker volume create \
#   --driver local \
#   --opt type=tmpfs \
#   --opt device=tmpfs \
#   my-tmp-volume
```
</details>