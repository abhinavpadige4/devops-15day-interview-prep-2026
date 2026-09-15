# Day 8: CI/CD with Jenkins

## Topics Covered
- Jenkins architecture (master/agent model)
- Jenkinsfile and Declarative Pipeline syntax
- Source code management integration (Git, SVN)
- Build triggers (polling, webhooks, cron)
- Parameterized builds
- Jenkins agents and labels
- Shared libraries
- Docker integration in pipelines
- Testing and reporting in pipelines
- Security and authentication
- Backup and disaster recovery
- Blue Ocean interface
- Pipeline as Code best practices

## Resources
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Pipeline Syntax Guide](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Jenkins Pipeline Tutorial](https://www.jenkins.io/doc/tutorials/build-a-java-app-with-maven/)
- [Declarative Pipeline Examples](https://www.jenkins.io/doc/book/pipeline/syntax/#declarative-pipeline)
- [Jenkins Docker Plugin](https://plugins.jenkins.io/docker-workflow/)
- [Jenkins Kubernetes Plugin](https://plugins.jenkins.io/kubernetes/)
- [Blue Ocean Documentation](https://www.jenkins.io/doc/book/blue-ocean/)
- [Jenkins Shared Libraries](https://www.jenkins.io/doc/book/pipeline/shared-libraries/)
- [Jenkins Security Advisory](https://www.jenkins.io/security/)

## Hands-on Exercises

### Exercise 1: Jenkins Installation and Setup
1. Install Jenkins on local machine or container
2. Configure initial setup and admin user
3. Install essential plugins (Git, Pipeline, Docker)
4. Configure Jenkins URL and system settings
5. Set up security realm and authorization

### Exercise 2: Declarative Pipeline Fundamentals
1. Create basic Declarative Pipeline
2. Define stages (build, test, deploy)
3. Use environment variables
4. Implement agent directives
5. Handle post-actions (success, failure, unstable)

### Exercise 3: Source Code Management and Triggers
1. Configure Git repository integration
2. Set up polling SCM triggers
3. Configure webhook triggers (GitHub/GitLab)
4. Use parameterized builds for branches/tags
5. Implement checkout and submodule handling

### Exercise 4: Docker Integration and Agents
1. Use Docker agent in pipelines
2. Build and push Docker images
3. Use Docker Compose in pipelines
4. Configure Jenkins agents (static, dynamic, cloud)
5. Implement distributed builds with labels

### Exercise 5: Advanced Pipeline Features
1. Create shared libraries for reusable code
2. Implement parallel stages
3. Use timeout and retry mechanisms
4. Handle credentials and secrets management
5. Generate and publish test reports

## Solutions

<details>
<summary>Exercise 1 Solutions: Jenkins Installation and Setup</summary>

```bash
# 1. Install Jenkins on local machine or container
echo "Installing Jenkins using Docker (recommended for learning)..."
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins-data:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts

# Alternative: Install on Ubuntu/Debian
# wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
# sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
# sudo apt update
# sudo apt install -y jenkins
# sudo systemctl start jenkins
# sudo systemctl enable jenkins

# 2. Configure initial setup and admin user
echo "Waiting for Jenkins to start..."
sleep 30

# Get initial admin password
INITIAL_ADMIN_PASSWORD=$(docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword)
echo "Initial admin password: $INITIAL_ADMIN_PASSWORD"
echo "Access Jenkins at: http://localhost:8080"
echo "Use the above password to complete setup wizard"

# 3. Install essential plugins (Git, Pipeline, Docker)
echo "Installing essential plugins via Jenkins CLI..."
# Download Jenkins CLI
JENKINS_URL="http://localhost:8080"
curl -sSL "$JENKINS_URL/jnlpJars/jenkins-cli.jar" -o jenkins-cli.jar

# Wait for Jenkins to be ready
until curl -s "$JENKINS_URL/login" | grep -i "sign in"; do
  echo "Waiting for Jenkins to be ready..."
  sleep 5
done

# Install plugins using CLI
java -jar jenkins-cli.jar -s $JENKINS_URL -auth admin:$INITIAL_ADMIN_PASSWORD install-plugin \
  git pipeline docker-workflow azure-ad oauth2-role-strategy matrix-auth

# Restart Jenkins to apply plugins
java -jar jenkins-cli.jar -s $JENKINS_URL -auth admin:$INITIAL_ADMIN_PASSWORD safe-restart

# 4. Configure Jenkins URL and system settings
echo "Configuring system settings via Jenkins CLI..."
java -jar jenkins-cli.jar -s $JENKINS_URL -auth admin:$INITIAL_ADMIN_PASSWORD \
  groovy = <<'EOF'
import jenkins.model.*
def instance = Jenkins.getInstance()
instance.setSystemMessage("DevOps Interview Prep Jenkins Instance")
instance.setNumExecutors(2)
instance.save()
EOF

# 5. Set up security realm and authorization
echo "Configuring basic security..."
java -jar jenkins-cli.jar -s $JENKINS_URL -auth admin:$INITIAL_ADMIN_PASSWORD \
  groovy = <<'EOF'
import jenkins.model.*
import hudson.security.*
def instance = Jenkins.getInstance()
def realm = new HudsonPrivateSecurityRealm(false)
realm.createAccount("devops", "DevOps123!")
instance.setSecurityRealm(realm)
def strategy = new hudson.security.FullControlOnceLoggedInAuthorizationStrategy()
instance.setAuthorizationStrategy(strategy)
instance.save()
EOF

echo "Jenkins setup complete!"
echo "Access at: http://localhost:8080"
echo "Login with: devops / DevOps123!"
```
</details>

<details>
<summary>Exercise 2 Solutions: Declarative Pipeline Fundamentals</summary>

```bash
# 1. Create basic Declarative Pipeline
echo "Creating basic Declarative Pipeline..."
cat > Jenkinsfile.basic << 'EOF'
pipeline {
    agent any
    
    stages {
        stage('Build') {
            steps {
                echo 'Building...'
                sh 'echo "Hello World"'
            }
        }
        stage('Test') {
            steps {
                echo 'Testing...'
                sh 'echo "Tests passed!"'
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying...'
                sh 'echo "Deployed successfully!"'
            }
        }
    }
    
    post {
        always {
            echo 'This will always run'
        }
        success {
            echo 'Build succeeded!'
        }
        failure {
            echo 'Build failed!'
        }
        unstable {
            echo 'Build was unstable'
        }
        changed {
            echo 'Things were different before...'
        }
    }
}
EOF

# 2. Define stages (build, test, deploy)
echo "Creating pipeline with detailed stages..."
cat > Jenkinsfile.detailed << 'EOF'
pipeline {
    agent any
    
    environment {
        REGISTRY = "docker.io/username"
        IMAGE_NAME = "myapp"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo 'Source code checked out'
            }
        }
        
        stage('Build') {
            steps {
                echo 'Building application...'
                sh '''
                echo "Building Docker image..."
                docker build -t ${REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER} .
                echo "Image built successfully"
                '''
            }
        }
        
        stage('Test') {
            steps {
                echo 'Running tests...'
                sh '''
                echo "Running unit tests..."
                # Example: run actual tests here
                echo "Unit tests passed"
                
                echo "Running integration tests..."
                # Example: integration tests
                echo "Integration tests passed"
                '''
            }
        }
        
        stage('Security Scan') {
            steps {
                echo 'Running security scans...'
                sh '''
                echo "Running container security scan..."
                # Example: trivy image ${REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}
                echo "Security scan completed"
                '''
            }
        }
        
        stage('Deploy') {
            when {
                branch 'main'
            }
            steps {
                echo 'Deploying to production...'
                sh '''
                echo "Pushing image to registry..."
                docker push ${REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}
                
                echo "Deploying to Kubernetes..."
                # Example: kubectl set image deployment/webapp webapp=${REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}
                echo "Deployment completed"
                '''
            }
        }
    }
    
    post {
        always {
            echo 'Cleaning up workspace...'
            cleanWs()
        }
        success {
            echo '🎉 Pipeline completed successfully!'
            mail to: 'dev-team@example.com',
                 subject: "Build ${env.BUILD_NUMBER} - SUCCESS",
                 body: "Pipeline executed successfully at ${env.BUILD_URL}"
        }
        failure {
            echo '❌ Pipeline failed!'
            mail to: 'dev-team@example.com',
                 subject: "Build ${env.BUILD_NUMBER} - FAILURE",
                 body: "Pipeline failed at ${env.BUILD_URL}"
        }
    }
}
EOF

# 3. Use environment variables
echo "Demonstrating environment variables usage..."
cat > Jenkinsfile.env-vars << 'EOF'
pipeline {
    agent any
    
    environment {
        DEPLOY_ENV = 'staging'
        BUILD_TOOL = 'maven'
        // Credentials from Jenkins credentials store
        DOCKER_HUB_CRED = credentials('docker-hub-id')
    }
    
    stages {
        stage('Show Environment') {
            steps {
                echo "Building on agent: ${env.AGENT_NAME}"
                echo "Build number: ${env.BUILD_NUMBER}"
                echo "Build ID: ${env.BUILD_ID}"
                echo "Job name: ${env.JOB_NAME}"
                echo "Executor number: ${env.EXECUTOR_NUMBER}"
                echo "Workspace: ${env.WORKSPACE}"
                echo "Git commit: ${env.GIT_COMMIT}"
                echo "Git branch: ${env.GIT_BRANCH}"
                echo "Deploy environment: ${DEPLOY_ENV}"
                echo "Build tool: ${BUILD_TOOL}"
            }
        }
    }
}
EOF

# 4. Implement agent directives
echo "Testing different agent options..."
cat > Jenkinsfile.agents << 'EOF'
pipeline {
    // Agent options:
    // agent any - Any available agent
    // agent none - No global agent, define per stage
    // agent { label 'docker' } - Specific label
    // agent { dockerfile true } - Build from Dockerfile
    // agent { docker { image 'maven:3.8-jdk-11' } } - Specific Docker image
    // agent { kubernetes { yamlFile 'pod-template.yaml' } } - Kubernetes pod
    
    agent { label 'docker' }
    
    stages {
        stage('Build with Maven') {
            agent {
                docker {
                    image 'maven:3.8-jdk-11'
                    args '-v $HOME/.m2:/root/.m2'
                }
            }
            steps {
                sh 'mvn -v'
                sh 'mvn clean package'
            }
        }
        
        stage('Run Tests') {
            agent {
                docker {
                    image 'openjdk:11-jre'
                }
            }
            steps {
                sh 'java -jar target/*.jar --help'
            }
        }
    }
}
EOF

# 5. Handle post-actions
echo "Creating pipeline with comprehensive post-actions..."
cat > Jenkinsfile.post-actions << 'EOF'
pipeline {
    agent any
    
    options {
        timeout(time: 1, unit: 'HOURS')
        timestamps()
        ansiColor('xterm')
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }
    
    stages {
        stage('Build') {
            steps {
                sh 'echo "Building application..."'
                sleep 2
                // Simulate build success/failure
                // returnStatus: true to continue even if step fails
                sh 'exit 0'  # Change to exit 1 to test failure handling
            }
        }
        
        stage('Test') {
            steps {
                sh 'echo "Running tests..."'
                sleep 2
                sh 'exit 0'
            }
        }
    }
    
    post {
        always {
            echo 'Cleaning up temporary files...'
            sh 'rm -rf tmp/* || true'
            archiveArtifacts artifacts: '**/target/*.jar', fingerprint: true
            junit '**/target/surefire-reports/*.xml'
        }
        success {
            echo '✅ Build successful!'
            slackSend channel: '#devops-builds', color: 'good', message: "Build ${env.BUILD_NUMBER} succeeded"
        }
        failure {
            echo '❌ Build failed!'
            slackSend channel: '#devops-alerts', color: 'danger', message: "Build ${env.BUILD_NUMBER} failed: ${env.BUILD_URL}"
            // Notify on-call engineer
            mail to: 'oncall@example.com',
                 subject: "ALERT: Build ${env.BUILD_NUMBER} FAILED",
                 body: "Build failed at ${env.BUILD_URL}\nCheck logs for details."
        }
        unstable {
            echo '⚠️ Build unstable (tests failed but build passed)'
        }
        changed {
            echo '🔄 Something changed since last build'
            mail to: 'team@example.com',
                 subject: "Changes detected in build ${env.BUILD_NUMBER}",
                 body: "Review changes at ${env.BUILD_URL}"
        }
        aborted {
            echo '🛑 Build was aborted'
        }
    }
}
EOF

# Cleanup test files
rm -f Jenkinsfile.* jenkins-cli.jar
```
</details>

<details>
<summary>Exercise 3 Solutions: Source Code Management and Triggers</summary>

```bash
# 1. Configure Git repository integration
echo "Setting up Git repository for Jenkins..."
# Create sample Git repository
mkdir -p sample-app
cd sample-app
git init

# Create sample application
cat > pom.xml << 'EOF'
<project>
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.example</groupId>
  <artifactId>sample-app</artifactId>
  <version>1.0-SNAPSHOT</version>
  <properties>
    <maven.compiler.source>11</maven.compiler.source>
    <maven.compiler.target>11</maven.compiler.target>
  </properties>
</project>
EOF

mkdir -p src/main/java/com/example
cat > src/main/java/com/example/App.java << 'EOF'
package com.example;

public class App {
    public static void main(String[] args) {
        System.out.println("Hello, World!");
    }
    
    public String getMessage() {
        return "Hello from Sample App!";
    }
}
EOF

# Initialize Git repo
git add .
git config user.name "DevOps Learner"
git config user.email "devops@example.com"
git commit -m "Initial commit: Sample Java application"

# 2. Set up polling SCM triggers
echo "Creating Jenkinsfile with polling trigger..."
cat > Jenkinsfile.polling << 'EOF'
pipeline {
    agent any
    
    triggers {
        // Poll SCM every 5 minutes
        pollSCM('*/5 * * * *')
        // Alternative cron expressions:
        // pollSCM('H/15 * * * *')  // Every 15 minutes, offset by hash
        // pollSCM('H H * * *')     // Once daily at random time
        // pollSCM('H H * * 0')     // Once weekly at random time on Sunday
    }
    
    stages {
        stage('Build') {
            steps {
                checkout scm
                sh 'mvn clean package'
            }
        }
        
        stage('Test') {
            steps {
                sh 'mvn test'
            }
        }
    }
}
EOF

# 3. Configure webhook triggers (GitHub/GitLab)
echo "Creating Jenkinsfile for webhook triggers..."
cat > Jenkinsfile.webhook << 'EOF'
pipeline {
    agent any
    
    options {
        // Disable polling when using webhooks
        disableConcurrentBuilds()
        // Skip default checkout if we want to do it manually
        skipDefaultCheckout()
    }
    
    stages {
        stage('Checkout') {
            steps {
                // Custom checkout with specific behavior
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    doGenerateSubmoduleConfigurations: false,
                    extensions: [
                        [$class: 'CleanBeforeCheckout'],
                        [$class: 'CleanCheckout'],
                        [$class: 'RelativeTargetDirectory', relativeTargetDir: 'app']
                    ],
                    submoduleCfg: [],
                    userRemoteConfigs: [
                        [
                            credentialsId: 'github-credentials',
                            url: 'https://github.com/username/sample-app.git'
                        ]
                    ]
                ])
            }
        }
        
        stage('Build') {
            steps {
                dir('app') {
                    sh 'mvn clean package'
                }
            }
        }
    }
}
EOF

# 4. Use parameterized builds for branches/tags
echo "Creating parameterized Jenkinsfile..."
cat > Jenkinsfile.parameterized << 'EOF'
pipeline {
    agent any
    
    parameters {
        string(name: 'DEPLOY_ENV', defaultValue: 'staging', description: 'Target deployment environment')
        choice(name: 'BUILD_TYPE', choices: ['unit', 'integration', 'full'], description: 'Type of tests to run')
        booleanParam(name: 'SKIP_TESTS', defaultValue: false, description: 'Skip test execution')
        string(name: 'GIT_BRANCH', defaultValue: 'main', description: 'Git branch to build')
        password(name: 'DEPLOY_TOKEN', defaultValue: '', description: 'Token for deployment')
    }
    
    environment {
        DEPLOY_ENV = "${params.DEPLOY_ENV}"
        BUILD_TYPE = "${params.BUILD_TYPE}"
        SKIP_TESTS = "${params.SKIP_TESTS}"
        GIT_BRANCH = "${params.GIT_BRANCH}"
    }
    
    stages {
        stage('Checkout Specific Branch') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: "*/${params.GIT_BRANCH}"]],
                    userRemoteConfigs: [[url: 'https://github.com/username/sample-app.git']]
                ])
            }
        }
        
        stage('Conditional Build') {
            steps {
                sh 'echo "Building application..."'
                sh 'mvn clean install -DskipTests=${params.SKIP_TESTS}'
            }
        }
        
        stage('Run Tests') {
            when {
                expression { return params.BUILD_TYPE == 'unit' || params.BUILD_TYPE == 'full' }
            }
            steps {
                sh 'echo "Running unit tests..."'
                sh 'mvn test'
            }
        }
        
        stage('Integration Tests') {
            when {
                expression { return params.BUILD_TYPE == 'integration' || params.BUILD_TYPE == 'full' }
            }
            steps {
                sh 'echo "Running integration tests..."'
                # Example: docker-compose up -d && run integration tests
                sh 'echo "Integration tests completed"'
            }
        }
        
        stage('Deploy') {
            when {
                expression { return params.DEPLOY_ENV == 'production' }
            }
            steps {
                echo "Deploying to production environment..."
                # Example deployment steps
                sh 'echo "Deployed to production using token: ********"'
            }
        }
    }
}
EOF

# 5. Implement checkout and submodule handling
echo "Creating Jenkinsfile with advanced Git features..."
cat > Jenkinsfile.advanced-git << 'EOF'
pipeline {
    agent any
    
    options {
        skipDefaultCheckout()  // Handle checkout manually
    }
    
    stages {
        stage('Initialize Repository') {
            steps {
                // Initialize Git repository
                sh 'git init'
                sh 'git remote add origin https://github.com/username/sample-app.git'
            }
        }
        
        stage('Fetch Specific Commit') {
            steps {
                // Fetch specific commit or tag
                sh 'git fetch origin main'
                sh 'git checkout abc123def456'  # Specific commit
                // or
                // sh 'git checkout v1.0.0'      # Specific tag
                // or
                // sh 'git checkout feature/new-feature'  # Specific branch
            }
        }
        
        stage('Handle Submodules') {
            steps {
                // Initialize and update submodules
                sh 'git submodule init'
                sh 'git submodule update --recursive'
                // Alternative: --remote to get latest from submodule repos
                // sh 'git submodule update --init --recursive --remote'
            }
        }
        
        stage('Verify Code') {
            steps {
                sh 'git status'
                sh 'git log --oneline -5'
                sh 'mvn validate'
            }
        }
    }
    
    post {
        always {
            // Clean up workspace
            sh 'git clean -fdx'
        }
    }
}
EOF

# Cleanup
cd ..
rm -rf sample-app Jenkinsfile.*
```
</details>

<details>
<summary>Exercise 4 Solutions: Docker Integration and Agents</summary>

```bash
# 1. Use Docker agent in pipelines
echo "Creating pipeline with Docker agent..."
cat > Jenkinsfile.docker-agent << 'EOF'
pipeline {
    agent {
        docker {
            image 'maven:3.8.4-openjdk-11-slim'
            args '-v $HOME/.m2:/root/.m2:z'
        }
    }
    
    stages {
        stage('Build') {
            steps {
                sh 'mvn -B clean package'
            }
        }
        
        stage('Test') {
            steps {
                sh 'mvn -B test'
            }
        }
    }
}
EOF

# 2. Build and push Docker images
echo "Creating pipeline for Docker image build and push..."
cat > Jenkinsfile.docker-build << 'EOF'
pipeline {
    agent any
    
    environment {
        // Credentials for Docker registry
        REGISTRY_CREDENTIALS = credentials('docker-hub')
        IMAGE_NAME = "mycompany/myapp"
        REGISTRY = "docker.io"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    // Build image with multiple tags
                    def image = "${REGISTRY}/${IMAGE_NAME}:${env.BUILD_NUMBER}"
                    def latest = "${REGISTRY}/${IMAGE_NAME}:latest"
                    
                    sh "docker build -t ${image} -t ${latest} ."
                    
                    // Store image names for later use
                    env.IMAGE = image
                    env.LATEST_IMAGE = latest
                }
            }
        }
        
        stage('Test Docker Image') {
            steps {
                sh "docker run --rm ${env.IMAGE} echo 'Container runs successfully'"
                # Add actual container tests here
                sh "docker run --rm ${env.IMAGE} /app/healthcheck.sh || echo 'Health check failed'"
            }
        }
        
        stage('Push Docker Image') {
            steps {
                // Authenticate with Docker registry
                withCredentials([usernamePassword(credentialsId: '${REGISTRY_CREDENTIALS}', 
                                              usernameVariable: 'REGISTRY_USER',
                                              passwordVariable: 'REGISTRY_PASS')]) {
                    sh "echo ${REGISTRY_PASS} | docker login ${REGISTRY} -u ${REGISTRY_USER} --password-stdin"
                    
                    // Push both tags
                    sh "docker push ${env.IMAGE}"
                    sh "docker push ${env.LATEST_IMAGE}"
                }
            }
        }
    }
    
    post {
        always {
            // Clean up Docker images to save space
            sh '''
            if [ -n "${env.IMAGE}" ]; then
                docker rmi ${env.IMAGE} ${env.LATEST_IMAGE} || true
            fi
            '''
        }
    }
}
EOF

# 3. Use Docker Compose in pipelines
echo "Creating pipeline with Docker Compose..."
cat > Jenkinsfile.docker-compose << 'EOF'
pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Start Services') {
            steps {
                // Start services defined in docker-compose.yml
                sh 'docker-compose -f docker-compose.yml up -d'
                
                // Wait for services to be healthy
                sh '''
                echo "Waiting for services to be ready..."
                for i in {1..30}; do
                    if docker-compose ps | grep -q "State: Up"; then
                        echo "Services are up!"
                        break
                    fi
                    echo "Waiting... attempt $i"
                    sleep 2
                done
                '''
            }
        }
        
        stage('Run Tests') {
            steps {
                // Run tests against the services
                sh 'docker-compose run --rm app npm test'
                # or
                # sh 'docker-compose exec app pytest tests/'
            }
        }
        
        stage('Cleanup') {
            steps {
                // Stop and remove containers, networks, images
                sh 'docker-compose down -v --rmi all --remove-orphans'
            }
        }
    }
    
    post {
        always {
            // Ensure cleanup even if pipeline fails
            sh 'docker-compose down -v || true'
        }
    }
}
EOF

# 4. Configure Jenkins agents (static, dynamic, cloud)
echo "Configuring different types of Jenkins agents..."
echo ""
echo "# 1. Static Agents (configured in Jenkins UI)"
echo "   - Go to Manage Jenkins > Manage Nodes and Clouds > New Node"
echo "   - Set: Permanent Agent"
echo "   - Configure: Launch method, workspace, labels, usage"
echo ""
echo "# 2. Dynamic Agents (Cloud providers)"
echo "   - Install appropriate cloud plugin (AWS, Azure, GCP, Kubernetes)"
echo "   - Configure cloud credentials"
echo "   - Set up agent templates with labels and resource limits"
echo ""
echo "# 3. Kubernetes Agents"
echo "   - Install Kubernetes Plugin"
echo "   - Configure Kubernetes credentials"
echo "   - Set up pod templates in Jenkins UI or via Jenkinsfile"
echo ""
echo "# 4. Docker Agents (as shown above)"
echo "   - Use docker agent directive in pipeline"
echo "   - Specify image, args, registry, etc."
echo ""
echo "# Example Kubernetes pod template:"
cat > jenkins-k8s-pod.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins: slave
    jenkins/agent: true
spec:
  containers:
  - name: jnlp
    image: jenkins/inbound-agent:latest
    resources:
      limits:
        memory: "2Gi"
        cpu: "1000m"
      requests:
        memory: "512Mi"
        cpu: "500m"
    env:
    - name: JENKINS_SECRET
      valueFrom:
        secretKeyRef:
          name: jenkins-agent
          key: secret
    - name: JENKINS_TUNNEL
      value: jenkins-agent:50000
    - name: JENKINS_AGENT_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
    - name: JENKINS_URL
      value: http://jenkins:8080
  - name: docker
    image: docker:20.10.16-dind
    privileged: true
    resources:
      limits:
        memory: "1Gi"
        cpu: "500m"
      requests:
        memory: "512Mi"
        cpu: "250m"
    env:
    - name: DOCKER_HOST
      value: tcp://localhost:2375
  volumeMounts:
  - name: docker-socket
    mountPath: /var/run/docker.sock
  volumes:
  - name: docker-socket
    hostPath:
      path: /var/run/docker.sock
EOF

# 5. Implement distributed builds with labels
echo "Creating pipeline that uses labeled agents..."
cat > Jenkinsfile.labeled-agents << 'EOF'
pipeline {
    // This pipeline will run on any agent with the 'docker' label
    agent { label 'docker' }
    
    stages {
        stage('Build') {
            steps {
                sh 'echo "Building on Docker-enabled agent..."'
                sh 'docker version'
                sh 'docker info'
            }
        }
        
        stage('Test') {
            // This stage will also run on the same agent (unless overridden)
            steps {
                sh 'echo "Running tests..."'
                sh 'docker run --rm hello-world'
            }
        }
        
        stage('Deploy') {
            // Override agent for this specific stage
            agent {
                // Could use a different label for deployment agents
                label 'deployment'
            }
            steps {
                sh 'echo "Deploying application..."'
                # Deployment steps here
            }
        }
    }
    
    // Alternative: Matrix build for multiple environments
    /*
    stages {
        stage('Test Matrix') {
            agent none
            steps {
                matrix {
                    axes {
                        axis {
                            name: 'PLATFORM'
                            values: ['linux', 'windows', 'macos']
                        }
                        axis {
                            name: 'VERSION'
                            values: ['1.0', '1.1', '1.2']
                        }
                    }
                    steps {
                        sh 'echo "Testing on ${PLATFORM} version ${VERSION}"'
                        # Actual test commands would go here
                    }
                }
            }
        }
    }
    */
}

# Cleanup
rm -f Jenkinsfile.* jenkins-k8s-pod.yaml
```
</details>

<details>
<summary>Exercise 5 Solutions: Advanced Pipeline Features</summary>

```bash
# 1. Create shared libraries for reusable code
echo "Setting up shared library structure..."
mkdir -p vars
mkdir -p src/org/example
mkdir -p resources

# Create a global variable function
cat > vars/shipIt.groovy << 'EOF'
def call(Map config = [:]) {
    def name = config.name ?: 'Application'
    def version = config.version ?: '1.0.0'
    def environment = config.environment ?: 'staging'
    
    echo "Shipping ${name} version ${version} to ${environment}"
    
    // Actual deployment logic would go here
    // sh "kubectl set image deployment/${name} ${name}=${registry}/${name}:${version}"
    // sh "kubectl rollout status deployment/${name}"
    
    return "Successfully deployed ${name} v${version} to ${environment}"
}
EOF

# Create another utility function
cat > vars/dockerUtils.groovy << 'EOF'
def buildAndPushImage(Map params = [:]) {
    def imageName = params.imageName ?: 'myapp'
    def tag = params.tag ?: 'latest'
    def registry = params.registry ?: 'docker.io'
    def credentialsId = params.credentialsId ?: 'docker-hub'
    
    def fullImageName = "${registry}/${imageName}:${tag}"
    
    echo "Building Docker image: ${fullImageName}"
    sh "docker build -t ${fullImageName} ."
    
    echo "Testing Docker image: ${fullImageName}"
    sh "docker run --rm ${fullImageName} echo 'Image works'"
    
    echo "Pushing Docker image: ${fullImageName}"
    withCredentials([usernamePassword(credentialsId: credentialsId,
                                      usernameVariable: 'REGISTRY_USER',
                                      passwordVariable: 'REGISTRY_PASS')]) {
        sh "echo ${REGISTRY_PASS} | docker login ${registry} -u ${REGISTRY_USER} --password-stdin"
        sh "docker push ${fullImageName}"
    }
    
    return fullImageName
}
EOF

# Create a custom step
cat > src/org/example/DeployStep.groovy << 'EOF'
package org.example

import org.jenkinsci.plugins.workflow.steps.*;
import org.jenkinsci.plugins.workflow.steps.StepContext;
import org.kohsuke.stapler.DataBoundConstructor;

import java.io.IOException;
import java.io.Serializable;
import java.util.*;

public class DeployStep extends Step implements Serializable {
    private final String environment;
    private final String serviceName;
    private final String image;
    
    @DataBoundConstructor
    public DeployStep(String environment, String serviceName, String image) {
        this.environment = environment;
        this.serviceName = serviceName;
        this.image = image;
    }
    
    public String getEnvironment() { return environment; }
    public String getServiceName() { return serviceName; }
    public String getImage() { return image; }
    
    @Override
    public StepExecution start(StepContext context) throws Exception {
        return new Execution(this, context);
    }
    
    public static class Execution extends StepExecution {
        private static final long serialVersionUID = 1L;
        private final DeployStep step;
        
        public Execution(DeployStep step, StepContext context) {
            super(context);
            this.step = step;
        }
        
        @Override
        public boolean start() throws IOException, InterruptedException {
            // Get the step context (provides access to Jenkins environment)
            StepContext context = getContext();
            
            // Perform deployment logic
            echo "Deploying ${step.serviceName} to ${step.environment}"
            echo "Using image: ${step.image}"
            
            // Example deployment commands
            // sh "kubectl set image deployment/${step.serviceName} ${step.serviceName}=${step.image}"
            // sh "kubectl rollout status deployment/${step.serviceName}"
            
            echo "Deployment completed successfully"
            return true;  // Indicates completion
        }
        
        @Override
        public void stop() throws IOException, InterruptedException {
            // Cleanup if needed
        }
    }
    
    // Descriptor for Jenkins to recognize this step
    @Extension
    public static class Descriptor extends StepDescriptor {
        @Override
        public String getFunctionName() {
            return "deployService"
        }
        
        @Override
        public String getDisplayName() {
            return "Deploy Service"
        }
        
        @Override
        public boolean takesImplicitBlockArgument() {
            return false
        }
    }
}
EOF

# Create resources for the shared library
cat > resources/org/example/deploy.txt << 'EOF'
This is a sample deployment template.
Environment: ${environment}
Service: ${serviceName}
Image: ${image}
EOF

# Create the shared library definition
cat > src/main/resources/org/example/Jenkinsfile << 'EOF'
# This would be in the shared library's own Jenkinsfile for testing
pipeline {
    agent any
    libraries {
        lib("my-shared-library")
    }
    
    stages {
        stage('Deploy') {
            steps {
                // Using the shared library functions
                script {
                    def result = shipIt name: 'WebApp', version: '1.2.3', environment: 'production'
                    echo result
                    
                    def image = dockerUtils.buildAndPushImage(
                        imageName: 'myapp',
                        tag: "${env.BUILD_NUMBER}",
                        credentialsId: 'docker-hub'
                    )
                    echo "Built and pushed: ${image}"
                }
                
                // Using custom step
                deployService environment: 'production',
                             serviceName: 'webapp',
                             image: 'docker.io/myapp:1.2.3'
            }
        }
    }
}
EOF

# 2. Implement parallel stages
echo "Creating pipeline with parallel stages..."
cat > Jenkinsfile.parallel << 'EOF'
pipeline {
    agent any
    
    stages {
        stage('Initial Build') {
            steps {
                checkout scm
                sh 'mvn clean compile'
            }
        }
        
        stage('Parallel Testing') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        sh 'mvn test'
                        junit '**/target/surefire-reports/*.xml'
                    }
                }
                
                stage('Integration Tests') {
                    steps {
                        sh 'echo "Setting up test environment..."'
                        sh 'docker-compose -f docker-compose.test.yml up -d'
                        sh 'sleep 10'  # Wait for services
                        sh 'mvn verify -Pintegration-tests'
                        sh 'docker-compose down -v'
                    }
                }
                
                stage('Performance Tests') {
                    steps {
                        sh 'echo "Running performance tests..."'
                        sh 'jmeter -n -t test-plan.jmx -l results.jtl'
                        sh 'echo "Performance tests completed"'
                    }
                }
                
                stage('Security Scans') {
                    steps {
                        sh 'echo "Running security scans..."'
                        sh 'trivy image ${REGISTRY}/${IMAGE}:${BUILD_NUMBER}'
                        sh 'bandit -r . -f json -o security-report.json'
                        sh 'echo "Security scans completed"'
                    }
                }
            }
        }
        
        stage('Aggregate Results') {
            steps {
                sh 'echo "Collecting test results..."'
                sh 'mkdir -p reports'
                sh 'cp **/target/surefire-reports/*.xml reports/ || true'
                sh 'cp security-report.json reports/ || true'
                sh 'cp results.jtl reports/ || true'
                
                echo "All parallel stages completed"
            }
        }
        
        stage('Deploy') {
            steps {
                sh 'echo "Deploying application..."'
                # Deployment steps
            }
        }
    }
}
EOF

# 3. Use timeout and retry mechanisms
echo "Creating pipeline with timeout and retry..."
cat > Jenkinsfile.timeout-retry << 'EOF'
pipeline {
    agent any
    
    options {
        timeout(time: 2, unit: 'HOURS')
        // Alternative timeout strategies:
        // timeout(time: 30, unit: 'MINUTES')
        // timeout(activity: true, time: 10, unit: 'MINUTES')  // Timeout if no activity for 10 min
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Unreliable Build') {
            steps {
                script {
                    // Retry mechanism for flaky steps
                    retry(3) {
                        sh '''
                        echo "Attempting build (attempt ${env.TRY_COUNT})..."
                        # Simulate flaky build that fails 2/3 times
                        RANDOM=$$((RANDOM % 3))
                        if [ $RANDOM -lt 2 ]; then
                            echo "Build failed, retrying..."
                            exit 1
                        else
                            echo "Build succeeded!"
                            exit 0
                        fi
                        '''
                    }
                }
            }
        }
        
        stage('External Service Call') {
            steps {
                // Timeout for external calls
                timeout(time: 5, unit: 'MINUTES') {
                    sh '''
                    echo "Calling external API..."
                    # Simulate slow external service
                    sleep 3
                    echo "API call completed"
                    '''
                }
                
                // Alternative: retry with timeout
                /*
                retry(count: 3) {
                    timeout(time: 2, unit: 'MINUTES') {
                        sh 'curl -s -m 10 https://api.example.com/health || exit 1'
                    }
                }
                */
            }
        }
        
        stage('Resource Intensive Task') {
            steps {
                // Use timestamps for better logging
                options {
                    timestamps()
                }
                sh '''
                echo "Starting resource intensive task..."
                date
                # Simulate long-running task
                for i in {1..10}; do
                    echo "Processing item $i"
                    sleep 3
                done
                date
                echo "Task completed"
                '''
            }
        }
    }
    
    post {
        always {
            echo 'Pipeline execution completed'
        }
        success {
            echo '✅ All stages completed successfully within time limits'
        }
        failure {
            echo '❌ Pipeline failed or timed out'
            # Could trigger alerting here
        }
    }
}
EOF

# 4. Handle credentials and secrets management
echo "Creating pipeline with secure credentials handling..."
cat > Jenkinsfile.credentials << 'EOF'
pipeline {
    agent any
    
    environment {
        // Access credentials stored in Jenkins
        DOCKER_HUB_USERNAME = credentials('docker-hub-username')
        DOCKER_HUB_PASSWORD = credentials('docker-hub-password')
        AWS_ACCESS_KEY_ID = credentials('aws-access-key')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')
        SSH_PRIVATE_KEY = credentials('ssh-private-key')
        SLACK_WEBHOOK_URL = credentials('slack-webhook')
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Docker Build and Push') {
            steps {
                // Method 1: Using withCredentials block
                withCredentials([usernamePassword(credentialsId: 'docker-hub',
                                                  usernameVariable: 'DOCKER_USER',
                                                  passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                    echo "Building Docker image..."
                    docker build -t myapp:${BUILD_NUMBER} .
                    
                    echo "Logging into Docker Hub..."
                    echo "${DOCKER_PASS}" | docker login -u "${DOCKER_USER}" --password-stdin
                    
                    echo "Pushing Docker image..."
                    docker push myapp:${BUILD_NUMBER}
                    '''
                }
                
                # Method 2: Using environment variables (less secure in logs)
                /*
                sh '''
                echo "Building Docker image..."
                docker build -t myapp:${BUILD_NUMBER} .
                
                echo "Logging into Docker Hub..."
                echo "${DOCKER_HUB_PASSWORD}" | docker login -u "${DOCKER_HUB_USERNAME}" --password-stdin
                
                echo "Pushing Docker image..."
                docker push myapp:${BUILD_NUMBER}
                '''
                */
            }
        }
        
        stage('AWS Deployment') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh '''
                    echo "Deploying to AWS..."
                    aws s3 cp myapp.jar s3://my-bucket/deploys/${BUILD_NUMBER}/
                    aws cloudformation deploy --template-file template.yaml --stack-name mystack
                    '''
                }
            }
        }
        
        stage('SSH Deployment') {
            steps {
                // Using SSH private key credentials
                sh '''
                echo "Setting up SSH access..."
                mkdir -p ~/.ssh
                echo "${SSH_PRIVATE_KEY}" > ~/.ssh/id_rsa
                chmod 600 ~/.ssh/id_rsa
                
                echo "Deploying via SSH..."
                ssh -o StrictHostKeyChecking=no user@server.com '
                    mkdir -p /opt/myapp
                    cp myapp.jar /opt/myapp/
                    systemctl restart myapp
                '
                '''
            }
        }
        
        stage('Notifications') {
            steps {
                // Send Slack notification
                sh '''
                echo "Sending Slack notification..."
                curl -X POST -H 'Content-type: application/json' \
                  --data '{"text":"Build ${env.BUILD_NUMBER} completed successfully!"}' \
                  ${SLACK_WEBHOOK_URL}
                '''
            }
        }
    }
    
    post {
        always {
            // Clean up sensitive data from workspace
            sh '''
            echo "Cleaning up sensitive data..."
            rm -rf ~/.ssh/id_rsa || true
            unset DOCKER_HUB_USERNAME DOCKER_HUB_PASSWORD
            unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
            unset SSH_PRIVATE_KEY SLACK_WEBHOOK_URL
            '''
        }
    }
}
EOF

# 5. Generate and publish test reports
echo "Creating pipeline with comprehensive test reporting..."
cat > Jenkinsfile.test-reports << 'EOF'
pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Unit Tests') {
            steps {
                sh 'mvn test'
                
                // Publish JUnit test results
                junit '**/target/surefire-reports/*.xml'
                
                // Publish test coverage reports (if using JaCoCo or similar)
                // cobertura coberturaReportFile: '**/target/site/jacoco/jacoco.xml'
                // or
                // publyshHTML(target: [
                //     allowMissing: false,
                //     alwaysLinkToLastBuild: true,
                //     keepAll: true,
                //     reportDir: 'target/site/jacoco',
                //     reportFiles: 'index.html',
                //     reportName: 'Coverage Report'
                // ])
            }
        }
        
        stage('Integration Tests') {
            steps {
                sh '''
                echo "Running integration tests..."
                # Example with pytest
                pytest tests/integration/ --junitxml=reports/integration.xml
                # or with Jest
                # jest --json --outputFile=reports/jest.json
                '''
                
                // Publish custom test results
                junit 'reports/integration.xml'
                // For JSON test results, you might need a plugin or custom parsing
            }
        }
        
        stage('Static Code Analysis') {
            steps {
                sh '''
                echo "Running static code analysis..."
                # Example with SonarQube
                # sonar-scanner
                # 
                # Example with ESLint
                # eslint src/ -f json -o eslint-report.json
                # 
                # Example with Hadolint for Dockerfiles
                # hadolint Dockerfile > hadolint-report.txt
                '''
                
                // Publish analysis results
                // publishHTML(target: [
                //     allowMissing: false,
                //     alwaysLinkToLastBuild: true,
                //     keepAll: true,
                //     reportDir: '.',
                //     reportFiles: 'eslint-report.json,hadolint-report.txt',
                //     reportNames: 'ESLint Report,Hadolint Report'
                // ])
            }
        }
        
        stage('Performance Tests') {
            steps {
                sh '''
                echo "Running performance tests..."
                # Example with JMeter
                # jmeter -n -t test-plan.jmx -l jmeter-results.jtl
                # 
                # Example with k6
                # k6 run test-script.js -o results.json
                '''
                
                // Publish performance results
                // Would need specific plugins or custom parsing for JMeter/k6 results
            }
        }
        
        stage('Generate Report') {
            steps {
                sh '''
                echo "Generating comprehensive test report..."
                mkdir -p reports
                
                # Collect all test results
                cp **/target/surefire-reports/*.xml reports/ 2>/dev/null || true
                cp reports/integration.xml reports/ 2>/dev/null || true
                cp reports/jest.json reports/ 2>/dev/null || true
                cp results.jtl reports/ 2>/dev/null || true
                cp eslint-report.json reports/ 2>/dev/null || true
                cp hadolint-report.txt reports/ 2>/dev/null || true
                
                # Generate summary
                echo "=== Test Report Summary ===" > reports/summary.txt
                echo "Build: ${env.BUILD_NUMBER}" >> reports/summary.txt
                echo "Timestamp: $(date)" >> reports/summary.txt
                echo "Unit Tests: $(find reports -name '*.xml' -exec grep -c 'testcase' {} \\; 2>/dev/null || echo 0)" >> reports/summary.txt
                echo "Test Files: $(ls -la reports/ | wc -l)" >> reports/summary.txt
                '''
            }
        }
    }
    
    post {
        always {
            // Archive all reports for long-term storage
            archiveArtifacts artifacts: 'reports/**', fingerprint: true, onlyIfSuccessful: true
            
            // Publish HTML report (requires HTML Publisher plugin)
            /*
            publishHTML(target: [
                allowMissing: false,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: 'reports',
                reportFiles: 'summary.txt',
                reportName: 'Test Summary'
            ])
            */
        }
        success {
            echo '📊 Test reports generated and archived'
            mail to: 'qa-team@example.com',
                 subject: "Test Report - Build ${env.BUILD_NUMBER}",
                 body: "Test reports available at ${env.BUILD_URL}artifact/reports/"
        }
        failure {
            echo '📊 Generating failure report...'
            sh '''
            echo "Build failed at $(date)" > reports/failure.txt
            echo "Build URL: ${env.BUILD_URL}" >> reports/failure.txt
            '''
            archiveArtifacts artifacts: 'reports/failure.txt', fingerprint: true
        }
    }
}
EOF

# Cleanup
rm -rf vars src resources Jenkinsfile.*
```
</details>