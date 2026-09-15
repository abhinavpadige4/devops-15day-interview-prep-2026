# Day 9: CI/CD with GitHub Actions

## Topics Covered
- GitHub Actions architecture and components
- Workflow YAML syntax and structure
- Events and triggers (push, pull_request, schedule, workflow_dispatch)
- Jobs and steps configuration
- Runners (GitHub-hosted vs self-hosted)
- Actions marketplace and custom actions
- Dependency caching
- Artifacts and logs
- Environment protection rules
- Concurrency and queuing
- Deployment strategies
- Security best practices
- Monitoring and debugging workflows

## Resources
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Workflow Syntax Reference](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [Events that Trigger Workflows](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows)
- [GitHub Actions Marketplace](https://github.com/marketplace?type=actions)
- [Creating Custom Actions](https://docs.github.com/en/actions/creating-actions)
- [Using Environments for Deployment Protection](https://docs.github.com/en/actions/deployment/using-environments-for-deployment-protection)
- [Caching Dependencies](https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows)
- [Artifacts in GitHub Actions](https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts)
- [Security Hardening for GitHub Actions](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)

## Hands-on Exercises

### Exercise 1: Basic Workflow Creation
1. Create first GitHub Actions workflow
2. Define workflow triggers and events
3. Configure jobs and steps
4. Use actions from the marketplace
5. View workflow runs and logs

### Exercise 2: CI Pipeline for Applications
1. Set up workflow for building applications
2. Implement testing strategies (unit, integration, e2e)
3. Use dependency caching for faster builds
4. Generate and upload test artifacts
5. Configure code quality checks

### Exercise 3: CD Pipeline and Deployments
1. Create deployment workflows to various platforms
2. Use environment protection rules
3. Implement blue/green and canary deployments
4. Deploy to Kubernetes, AWS, Azure, GCP
5. Use deployment status and branch protection

### Exercise 4: Advanced Workflow Features
1. Create reusable workflows
2. Use matrix builds for multi-platform testing
3. Implement concurrency groups and cancellation
4. Use workflow run artifacts for debugging
5. Create custom actions for organization reuse

### Exercise 5: Security and Best Practices
1. Implement security hardening practices
2. Use secrets and environment variables securely
3. Configure branch protection and required checks
4. Implement code scanning and dependency review
5. Audit workflow logs and access controls

## Solutions

<details>
<summary>Exercise 1 Solutions: Basic Workflow Creation</summary>

```bash
# 1. Create first GitHub Actions workflow
echo "Creating basic GitHub Actions workflow..."
mkdir -p .github/workflows

cat > .github/workflows/basic-ci.yml << 'EOF'
name: Basic CI Workflow

# 2. Define workflow triggers and events
on:
  push:
    branches: [ main, develop ]
    paths:
      - 'src/**'
      - '*.js'
      - '*.ts'
      - 'package.json'
  pull_request:
    branches: [ main ]
  workflow_dispatch:  # Manual trigger
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM UTC

# 3. Configure jobs and steps
jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Set up Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
        cache: 'npm'
        
    - name: Install dependencies
      run: npm ci
      
    - name: Run build
      run: npm run build
      
    - name: Run tests
      run: npm test
      
    - name: Upload build artifact
      uses: actions/upload-artifact@v3
      with:
        name: build-files
        path: dist/
EOF

# 4. Use actions from the marketplace
echo "Creating workflow with marketplace actions..."
cat > .github/workflows/marketplace-actions.yml << 'EOF'
name: Marketplace Actions Demo

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Setup Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.9'
        
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install flake8 pytest
        if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
        
    - name: Lint code with flake8
      uses: py-actions/flake8@v2
      with:
        # GitHub Action name: py-actions/flake8
        # Installs flake8 and runs it on your code
        token: ${{ secrets.GITHUB_TOKEN }}
        
    - name: Run tests with pytest
      run: pytest tests/ -v
      
    - name: Security scan with Bandit
      uses: py-actions/bandit@v2
      with:
        # GitHub Action name: py-actions/bandit
        # Security linter for Python
        
    - name: Create GitHub Release
      uses: softprops/action-gh-release@v1
      if: startsWith(github.ref, 'refs/tags/')
      with:
        tag_name: ${{ github.ref_name }}
        name: Release ${{ github.ref_name }}
        draft: false
        prerelease: false
EOF

# 5. View workflow runs and logs
echo "To view workflow runs:"
echo "1. Go to your repository on GitHub"
echo "2. Click on the 'Actions' tab"
echo "3. Select the workflow from the left sidebar"
echo "4. Click on a specific workflow run"
echo "5. Expand jobs and steps to see detailed logs"
echo ""
echo "Alternative: Use GitHub CLI"
echo "gh run list"
echo "gh run view <RUN_ID>"
echo "gh run watch <RUN_ID>"
```
</details>

<details>
<summary>Exercise 2 Solutions: CI Pipeline for Applications</summary>

```bash
# 1. Set up workflow for building applications
echo "Creating CI pipeline for Node.js application..."
cat > .github/workflows/nodejs-ci.yml << 'EOF'
name: Node.js CI Pipeline

on:
  push:
    branches: [ main, develop ]
    paths-ignore:
      - 'README.md'
      - '*.md'
  pull_request:
    branches: [ main ]

jobs:
  build-test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [16.x, 18.x, 20.x]
    
    services:
      # Add services like databases for integration tests
      postgres:
        image: postgres:13
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: test_db
        ports: [5432:5432]
        # Set health checks to wait until postgres has started
        options: >-
          --health-cmd="pg_isready -U postgres -d test_db"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=5
    
    env:
      NODE_ENV: test
      DATABASE_URL: postgres://postgres:postgres@localhost:5432/test_db
      POSTGRES_HOST: localhost
      POSTGRES_PORT: 5432
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: test_db
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Setup Node.js ${{ matrix.node-version }}
      uses: actions/setup-node@v3
      with:
        node-version: ${{ matrix.node-version }}
        cache: 'npm'
        
    - name: Install dependencies
      run: npm ci
      
    - name: Run linting
      run: npm run lint
      
    - name: Run unit tests
      run: npm test
      
    - name: Run integration tests
      env:
        DATABASE_URL: ${{ env.DATABASE_URL }}
      run: npm run test:integration
      
    - name: Generate test coverage
      run: npm run test:coverage
      
    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        file: ./coverage.xml
        flags: unittests
        name: codecov-umbrella
        fail_ci_if_error: true
        
    - name: Upload build artifact
      uses: actions/upload-artifact@v3
      with:
        name: nodejs-app
        path: dist/
        retention-days: 7
EOF

# 2. Implement testing strategies (unit, integration, e2e)
echo "Creating comprehensive testing workflow..."
cat > .github/workflows/comprehensive-testing.yml << 'EOF'
name: Comprehensive Testing

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ '**' ]

jobs:
  # Unit Tests
  unit-tests:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v3
      with:
        node-version: '18'
        cache: 'npm'
    - run: npm ci
    - run: npm test -- --coverage --reporter=json --outputFile=coverage-unit.json
    - uses: actions/upload-artifact@v3
      with:
        name: unit-test-results
        path: |
          coverage-unit.json
          coverage/
    - uses: actions/upload-artifact@v3
      with:
        name: coverage-report
        if: always()
        path: coverage/
        
  # Integration Tests
  integration-tests:
    runs-on: ubuntu-latest
    services:
      mongodb:
        image: mongo:5
        ports: [27017:27017]
        options: >-
          --health-cmd="mongo --eval 'db.runCommand({ ping: 1 })'"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=5
    steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v3
      with:
        node-version: '18'
    - run: npm ci
    - env:
        MONGODB_URI: mongodb://localhost:27017/testdb
      run: npm run test:integration
    - uses: actions/upload-artifact@v3
      with:
        name: integration-test-results
        path: test-results/
        
  # End-to-End Tests
  e2e-tests:
    runs-on: ubuntu-latest
    services:
      selenium:
        image: selenium/standalone-chrome
        ports: [4444:4444]
        options: >-
          --shm-size=2g
    steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v3
      with:
        node-version: '18'
    - run: npm ci
    - run: npx playwright install-deps
    - run: npx playwright install chromium
    - env:
        BASE_URL: http://localhost:3000
      run: npx playwright test
    - uses: actions/upload-artifact@v3
      with:
        name: playwright-report
        if: always()
        path: playwright-report/
    - uses: actions/upload-artifact@v3
      with:
        name: trace-files
        if: always()
        path: **/
EOF

# 3. Use dependency caching for faster builds
echo "Creating workflow with advanced caching strategies..."
cat > .github/workflows/advanced-caching.yml << 'EOF'
name: Advanced Caching Strategies

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Cache Node.js modules
      id: npm-cache
      uses: actions/cache@v3
      with:
        path: ~/.npm
        key: ${{ runner.os }}-node-${{ hashFiles('package-lock.json') }}
        restore-keys: |
          ${{ runner.os }}-node-
          
    - name: Cache pip dependencies
      id: pip-cache
      uses: actions/cache@v3
      with:
        path: ~/.cache/pip
        key: ${{ runner.os }}-pip-${{ hashFiles('requirements.txt') }}
        restore-keys: |
          ${{ runner.os }}-pip-
          
    - name: Cache Maven repository
      id: maven-cache
      uses: actions/cache@v3
      with:
        path: ~/.m2/repository
        key: ${{ runner.os }}-maven-${{ hashFiles('pom.xml') }}
        restore-keys: |
          ${{ runner.os }}-maven-
          
    - name: Cache Go modules
      id: go-cache
      uses: actions/cache@v3
      with:
        path: |
          ~/.cache/go-build
          ~/go/pkg/mod
        key: ${{ runner.os }}-go-${{ hashFiles('go.sum') }}
        restore-keys: |
          ${{ runner.os }}-go-
          
    - name: Cache Docker layers
      id: docker-cache
      uses: actions/cache@v3
      with:
        path: /tmp/.buildx-cache
        key: ${{ runner.os }}-docker-${{ github.sha }}
        restore-keys: |
          ${{ runner.os }}-docker-
          
    - name: Install dependencies
      run: |
        # Install all dependencies after caches are restored
        npm ci
        pip install -r requirements.txt
        mvn dependency:resolve
        go mod download
        
    - name: Build application
      run: |
        npm run build
        mvn clean package
        go build -o myapp .
        
    - name: Upload build artifacts
      uses: actions/upload-artifact@v3
      with:
        name: build-artifacts
        path: |
          dist/
          target/*.jar
          myapp
EOF

# 4. Generate and upload test artifacts
echo "Creating workflow for test artifact management..."
cat > .github/workflows/test-artifacts.yml << 'EOF'
name: Test Artifacts Management

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: [3.8, 3.9, 3.10]
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Setup Python
      uses: actions/setup-python@v4
      with:
        python-version: ${{ matrix.python-version }}
        cache: 'pip'
        
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install pytest pytest-cov
        
    - name: Run tests with coverage
      run: |
        pytest --cov=./ --cov-report=xml --cov-report=html --tb=short
        
    - name: Upload test results
      uses: actions/upload-artifact@v3
      with:
        name: test-results-python${{ matrix.python-version }}
        path: |
          xmlreport.xml
          htmlcov/
          pytest.log
        retention-days: 14
        
    - name: Upload coverage report
      if: always()
      uses: actions/upload-artifact@v3
      with:
        name: coverage-python${{ matrix.python-version }}
        path: coverage.xml
        
  # Aggregate test results from all matrix jobs
  aggregate:
    needs: test
    runs-on: ubuntu-latest
    if: always()
    steps:
    - name: Download all test artifacts
      uses: actions/download-artifact@v3
      with:
        name: test-results
        path: test-artifacts/
        
    - name: Generate test summary
      run: |
        echo "=== Test Summary ===" > test-summary.txt
        echo "Workflow Run: ${{ github.run_id }}" >> test-summary.txt
        echo "Timestamp: $(date)" >> test-summary.txt
        echo "" >> test-summary.txt
        
        # Count test files
        find test-artifacts -name "*.xml" | while read file; do
          echo "File: $file" >> test-summary.txt
          grep -c "testcase" "$file" >> test-summary.txt 2>/dev/null || echo "0" >> test-summary.txt
        done
        
        echo "" >> test-summary.txt
        echo "Total test artifacts: $(find test-artifacts -type f | wc -l)" >> test-summary.txt
        
    - name: Upload test summary
      uses: actions/upload-artifact@v3
      with:
        name: test-summary
        path: test-summary.txt
EOF

# 5. Configure code quality checks
echo "Creating workflow for code quality checks..."
cat > .github/workflows/code-quality.yml << 'EOF'
name: Code Quality Checks

on:
  push:
    branches: [ main, develop ]
    paths-ignore:
      - 'README.md'
      - '*.md'
      - '*.txt'
  pull_request:
    branches: [ main ]

jobs:
  # Security scanning
  security:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Run Snyk to check for vulnerabilities
      uses: snyk/actions@v2
      with:
        command: test
        # Or use: snyk/actions@master
        # env:
        #   SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        
    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@0.6.3
      with:
        scan-type: 'fs'
        ignore-unfixed: true
        format: 'sarif'
        output: 'trivy-results.sarif'
        
    - name: Upload Trivy results to GitHub Code Scanning
      uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: 'trivy-results.sarif'
        
  # Code linting and formatting
  linting:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
        
    - name: Install dependencies
      run: npm ci
      
    - name: Run ESLint
      run: npx eslint . --format=json --output-file=eslint-report.json
      
    - name: Run Prettier check
      run: npx prettier --check .
      
    - name: Upload ESLint results
      if: always()
      uses: actions/upload-artifact@v3
      with:
        name: eslint-report
        path: eslint-report.json
        
    - name: Comment on PR with linting results
      if: github.event_name == 'pull_request'
      uses: actions/github-script@v6
      with:
        script: |
          const fs = require('fs');
          const report = JSON.parse(fs.readFileSync('eslint-report.json', 'utf8'));
          const issueCount = report.length;
          
          github.rest.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: `ESLint found ${issueCount} issues. Please fix them before merging.`
          });
          
  # Dependency checking
  dependencies:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Check for outdated npm packages
      id: npm-outdated
      run: |
        npm outdated --json > outdated-packages.json || true
        echo "outdated_count=$(jq 'length' outdated-packages.json 2>/dev/null || echo 0)" >> $GITHUB_OUTPUT
        
    - name: Check for outdated Python packages
      id: python-outdated
      run: |
        pip list --outdated --format=json > outdated-python.json || true
        echo "outdated_count=$(python -c \"import json; print(len(json.load(open('outdated-python.json'))))\" 2>/dev/null || echo 0)" >> $GITHUB_OUTPUT
        
    - name: Create issue for outdated dependencies
      if: |
        (steps.npm-outdated.outputs.outdated_count != '0' ||
         steps.python-outdated.outputs.outdated_count != '0')
      uses: actions/github-script@v6
      with:
        script: |
          const outdatedCount = parseInt("${{ steps.npm-outdated.outputs.outdated_count }}") +
                               parseInt("${{ steps.python-outdated.outputs.outdated_count }}");
          
          if (outdatedCount > 0) {
            github.rest.issues.create({
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: `Dependency Update Available: ${outdatedCount} packages outdated`,
              body: `Found ${outdatedCount} outdated dependencies that should be updated.`,
              labels: ['dependencies', 'outdated']
            });
          }
EOF

# Cleanup test files
rm -rf .github/workflows/*
```
</details>

<details>
<summary>Exercise 3 Solutions: CD Pipeline and Deployments</summary>

```bash
# 1. Create deployment workflows to various platforms
echo "Creating deployment workflow to Kubernetes..."
cat > .github/workflows/deploy-k8s.yml << 'EOF'
name: Deploy to Kubernetes

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment:
      name: production
      url: ${{ steps.deploy-to-k8s.outputs.cluster-url }}
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Set up Kubernetes
      uses: azure/setup-kubectl@v3
      with:
        version: 'v1.27.0'
        
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-east-1
        
    - name: Authenticate to Amazon EKS
      id: auth-eks
      uses: aws-actions/amazon-eks-login@v2
      with:
        cluster-name: my-production-cluster
        region: us-east-1
        
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v2
      
    - name: Login to Amazon ECR
      uses: aws-actions/amazon-ecr-login@v2
      
    - name: Build and push Docker image
      id: build-image
      uses: docker/build-push-action@v4
      with:
        context: .
        push: true
        tags: |
          ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.${{ secrets.AWS_REGION }}.amazonaws.com/myapp:${{ github.sha }}
          ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.${{ secrets.AWS_REGION }}.amazonaws.com/myapp:latest
        cache-from: type=registry,ref=${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.${{ secrets.AWS_REGION }}.amazonaws.com/myapp:cache
        cache-to: type=inline
        
    - name: Deploy to Kubernetes
      id: deploy-to-k8s
      uses: ./kubernetes-deploy-action  # Custom action or use existing
      with:
        namespace: production
        deployment-name: myapp
        image: ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.${{ secrets.AWS_REGION }}.amazonaws.com/myapp:${{ github.sha }}
        container-name: myapp
        
    - name: Verify deployment
      run: |
        kubectl -n production get deployment myapp
        kubectl -n production get pods -l app=myapp
        kubectl -n production rollout status deployment/myapp
        
    - name: Post deployment notification
      if: success()
      uses: slackapi/slack-github-action@v1.23.0
      with:
        payload: |
          {
            "text": ":rocket: Deployment successful! Application deployed to Kubernetes cluster.",
            "attachments": [
              {
                "color": "good",
                "fields": [
                  {
                    "title": "Environment",
                    "value": "Production",
                    "short": true
                  },
                  {
                    "title": "Commit",
                    "value": "${{ github.sha }}",
                    "short": true
                  },
                  {
                    "title": "Workflow Run",
                    "value": "<${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}|View Details>",
                    "short": true
                  }
                ]
              }
            ]
          }
      env:
        SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
        SLACK_WEBHOOK_TYPE: INCOMING_WEBHOOK
EOF

# 2. Use environment protection rules
echo "Creating workflow with environment protection..."
cat > .github/workflows/deploy-with-protection.yml << 'EOF'
name: Deploy with Protection Rules

on:
  push:
    tags:
      - 'v*'  # Deploy on version tags
  workflow_dispatch:

jobs:
  deploy-staging:
    runs-on: ubuntu-latest
    environment:
      name: staging
      url: https://staging.example.com
    
    steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v3
      with:
        node-version: '18'
    - run: npm ci
    - run: npm run build
    - name: Deploy to Staging
      run: |
        echo "Deploying to staging environment..."
        # Deployment commands here
        echo "Staging deployment completed"
        
  deploy-production:
    needs: deploy-staging
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://example.com
      # Protection rules configured in GitHub repository settings:
      # - Required reviewers: team-lead, architecture
      # - Wait timer: 10 minutes
      # - Deployment branches: main
      # - Environment variables: PROD_API_KEY, DB_CONNECTION_STRING
    steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v3
      with:
        node-version: '18'
    - run: npm ci
    - run: npm run build
    - name: Deploy to Production
      run: |
        echo "Deploying to production environment..."
        # Deployment commands here
        echo "Production deployment completed"
        
    - name: Post deployment notification
      if: success()
      uses: slackapi/slack-github-action@v1.23.0
      with:
        payload: |
          {
            "text": ":rocket: Production deployment successful!",
            "attachments": [
              {
                "color": "good",
                "fields": [
                  {
                    "title": "Version",
                    "value": "${{ github.ref_name }}",
                    "short": true
                  },
                  {
                    "title": "Environment",
                    "value": "Production",
                    "short": true
                  }
                ]
              }
            ]
          }
      env:
        SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
EOF

# 3. Implement blue/green and canary deployments
echo "Creating blue/green deployment workflow..."
cat > .github/workflows/blue-green-deploy.yml << 'EOF'
name: Blue/Green Deployment

on:
  push:
    branches: [ main ]

jobs:
  blue-green-deploy:
    runs-on: ubuntu-latest
    environment: production
    
    steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v3
      with:
        node-version: '18'
    - run: npm ci
    - run: npm run build
    
    - name: Configure Kubernetes
      uses: azure/setup-kubectl@v3
      
    - name: Set up cloud credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-east-1
        
    - name: Authenticate to EKS
      uses: aws-actions/amazon-eks-login@v2
      with:
        cluster-name: my-cluster
        region: us-east-1
        
    - name: Get current active service
      id: current-service
      run: |
        # Get the service that's currently receiving traffic
        CURRENT_SERVICE=$(kubectl get svc myapp-service -o jsonpath='{.spec.selector.version}')
        echo "current_service=$CURRENT_SERVICE" >> $GITHUB_OUTPUT
        
    - name: Determine target version
      id: target-version
      run: |
        if [[ "${{ steps.current-service.outputs.current_service }}" == "blue" ]]; then
          echo "target_version=green" >> $GITHUB_OUTPUT
          echo "deploy_version=v2" >> $GITHUB_OUTPUT
        else
          echo "target_version=blue" >> $GITHUB_OUTPUT
          echo "deploy_version=v1" >> $GITHUB_OUTPUT
        fi
        
    - name: Deploy to inactive environment
      run: |
        echo "Deploying to ${{ steps.target-version.outputs.target_version }} environment..."
        kubectl set image deployment/myapp-${{ steps.target-version.outputs.target_version }} \
          myapp=myregistry/myapp:${{ github.sha }} \
          -n production
        kubectl rollout status deployment/myapp-${{ steps.target-version.outputs.target_version }} -n production
        
    - name: Run smoke tests
      run: |
        echo "Running smoke tests on new deployment..."
        # Example smoke tests
        sleep 10
        echo "Smoke tests passed"
        
    - name: Switch traffic to new version
      run: |
        echo "Switching traffic to ${{ steps.target-version.outputs.target_version }}..."
        kubectl patch svc myapp-service -n production -p '{"spec":{"selector":{"version":"${{ steps.target-version.outputs.target_version }}"}}}'
        
    - name: Monitor and verify
      run: |
        echo "Monitoring deployment for 5 minutes..."
        sleep 300
        echo "Deployment verified successfully"
        
    - name: Cleanup old version (optional)
      if: always()
      run: |
        echo "Optional: Cleaning up old deployment..."
        # Uncomment to automatically remove old version after verification
        # kubectl delete deployment/myapp-${{ steps.current-service.outputs.current_service }} -n production
EOF

# 4. Deploy to Kubernetes, AWS, Azure, GCP
echo "Creating multi-cloud deployment examples..."
cat > .github/workflows/multi-cloud-deploy.yml << 'EOF'
name: Multi-Cloud Deployment

on:
  workflow_dispatch:
    inputs:
      target-cloud:
        description: 'Target cloud provider'
        required: true
        default: 'aws'
        options: ['aws', 'azure', 'gcp']

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production
    
    steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v3
      with:
        node-version: '18'
    - run: npm ci
    - run: npm run build
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v2
      
    - name: Deploy to AWS
      if: ${{ inputs.target-cloud == 'aws' }}
      uses: ./.github/actions/deploy-aws
      with:
        cluster-name: ${{ secrets.AWS_EKS_CLUSTER }}
        region: ${{ secrets.AWS_REGION }}
        account-id: ${{ secrets.AWS_ACCOUNT_ID }}
        
    - name: Deploy to Azure
      if: ${{ inputs.target-cloud == 'azure' }}
      uses: azure/aks-set-context@v3
      with:
        resource-group: ${{ secrets.AZURE_RESOURCE_GROUP }}
        cluster-name: ${{ secrets.AZURE_AKS_CLUSTER }}
        subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
        
    - name: Deploy to GCP
      if: ${{ inputs.target-cloud == 'gcp' }}
      uses: google-github-actions/get-gke-credentials@v2
      with:
        cluster-name: ${{ secrets.GCP_GKE_CLUSTER }}
        location: ${{ secrets.GCP_GKE_LOCATION }}
        project-id: ${{ secrets.GCP_PROJECT_ID }}
        
    - name: Common deployment steps
      run: |
        echo "Deploying application to ${{ inputs.target-cloud }}..."
        # Common steps for all clouds
        echo "Building and pushing container image..."
        # Cloud-specific deployment would happen in the respective actions above
        
    - name: Verify deployment
      run: |
        echo "Verifying deployment on ${{ inputs.target-cloud }}..."
        # Cloud-specific verification logic
EOF

# 5. Use deployment status and branch protection
echo "Creating workflow that uses deployment status..."
cat > .github/workflows/deployment-status.yml << 'EOF'
name: Deployment Status Tracking

on:
  push:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      image-tag: ${{ steps.build-image.outputs.image-tag }}
    steps:
    - uses: actions/checkout@v4
    - name: Build and tag Docker image
      id: build-image
      run: |
        IMAGE_TAG="myapp:${{ github.sha }}"
        echo "image-tag=$IMAGE_TAG" >> $GITHUB_OUTPUT
        echo "Building image: $IMAGE_TAG"
        # docker build -t $IMAGE_TAG .
        
  deploy-staging:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: staging
      url: https://staging.example.com
    steps:
    - uses: actions/checkout@v4
    - name: Deploy to staging
      run: |
        echo "Deploying image ${{ needs.build.outputs.image-tag }} to staging"
        # Deployment commands
        
  deploy-production:
    needs: [build, deploy-staging]
    runs-on: ubuntu-latest
    # This job will only run if the staging deployment succeeded
    if: ${{ needs.deploy-staging.result == 'success' }}
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://example.com
    steps:
    - uses: actions/checkout@v4
    - name: Deploy to production
      run: |
        echo "Deploying image ${{ needs.build.outputs.image-tag }} to production"
        # Deployment commands
        
    # This will automatically update the deployment status in GitHub
    # which can be used for branch protection rules
EOF

# Cleanup
rm -rf .github/workflows/*
```
</details>

<details>
<summary>Exercise 4 Solutions: Advanced Workflow Features</summary>

```bash
# 1. Create reusable workflows
echo "Creating reusable workflow..."
mkdir -p .github/workflows

# Create reusable workflow for building and testing
cat > .github/workflows/reusable-build-test.yml << 'EOF'
name: Reusable Build and Test

# This workflow can be called from other workflows
on:
  workflow_call:
    inputs:
      node-version:
        description: 'Node.js version to use'
        required: true
        type: string
        default: '18.x'
      build-command:
        description: 'Custom build command'
        required: false
        type: string
        default: 'npm run build'
      test-command:
        description: 'Custom test command'
        required: false
        type: string
        default: 'npm test'
    secrets:
      npm-token:
        description: 'NPM token for private packages'
        required: false
    outputs:
      build-artifact:
        description: 'Path to build artifact'
        value: ${{ jobs.build.outputs.artifact-path }}
      test-results:
        description: 'Path to test results'
        value: ${{ jobs.test.outputs.results-path }}
    
    jobs:
      build:
        runs-on: ubuntu-latest
        outputs:
          artifact-path: ${{ steps.build.outputs.artifact }}
        steps:
        - uses: actions/checkout@v4
        - uses: actions/setup-node@v3
          with:
            node-version: ${{ inputs.node-version }}
            cache: 'npm'
        - name: Install dependencies
          run: npm ci
          env:
            NODE_AUTH_TOKEN: ${{ secrets.npm-token }}
        - name: Build application
          id: build
          run: |
            ${{ inputs.build-command }}
            echo "artifact=dist/" >> $GITHUB_OUTPUT
            
      test:
        needs: build
        runs-on: ubuntu-latest
        outputs:
          results-path: ${{ steps.test.outputs.results }}
        steps:
        - uses: actions/checkout@v4
        - uses: actions/setup-node@v3
          with:
            node-version: ${{ inputs.node-version }}
            cache: 'npm'
        - name: Install dependencies
          run: npm ci
          env:
            NODE_AUTH_TOKEN: ${{ secrets.npm-token }}
        - name: Run tests
          id: test
          run: |
            ${{ inputs.test-command }}
            echo "results=test-results/" >> $GITHUB_OUTPUT
EOF

# Create another reusable workflow for deployment
cat > .github/workflows/reusable-deploy.yml << 'EOF'
name: Reusable Deployment

on:
  workflow_call:
    inputs:
      environment:
        description: 'Target environment'
        required: true
        type: string
      image-url:
        description: 'Docker image URL to deploy'
        required: true
        type: string
      kubernetes-namespace:
        description: 'Kubernetes namespace'
        required: false
        type: string
        default: 'default'
    secrets:
      kube-config:
        description: 'Kubernetes configuration'
        required: true
      docker-registry-url:
        description: 'Docker registry URL'
        required: false
      docker-username:
        description: 'Docker registry username'
        required: false
      docker-password:
        description: 'Docker registry password'
        required: false
    
    jobs:
      deploy:
        runs-on: ubuntu-latest
        environment: ${{ inputs.environment }}
        steps:
        - name: Configure Kubernetes
          uses: azure/setup-kubectl@v3
          with:
            kubeconfig: ${{ secrets.kube-config }}
            
        - name: Set up Docker registry credentials
          if: ${{ secrets.docker-registry-url }}
          uses: docker/login-action@v2
          with:
            registry: ${{ secrets.docker-registry-url }}
            username: ${{ secrets.docker-username }}
            password: ${{ secrets.docker-password }}
            
        - name: Deploy to Kubernetes
          run: |
            echo "Deploying ${{ inputs.image-url }} to ${{ inputs.environment }} namespace ${{ inputs.kubernetes-namespace }}"
            kubectl set image deployment/myapp myapp=${{ inputs.image-url }} -n ${{ inputs.kubernetes-namespace }}
            kubectl rollout status deployment/myapp -n ${{ inputs.kubernetes-namespace }}
            
        - name: Verify deployment
          run: |
            kubectl get deployment myapp -n ${{ inputs.kubernetes-namespace }}
            kubectl get pods -l app=myapp -n ${{ inputs.kubernetes-namespace }}
EOF

# 2. Use matrix builds for multi-platform testing
echo "Creating matrix build workflow..."
cat > .github/workflows/matrix-build.yml << 'EOF'
name: Matrix Build and Test

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build-test:
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        node-version: [14.x, 16.x, 18.x]
        # Exclude incompatible combinations
        exclude:
          - os: windows-latest
            node-version: '14.x'
        include:
          - os: ubuntu-latest
            node-version: '20.x'
            # Additional testing for latest LTS on Ubuntu
    
    steps:
    - uses: actions/checkout@v4
    - name: Setup Node.js ${{ matrix.node-version }}
      uses: actions/setup-node@v3
      with:
        node-version: ${{ matrix.node-version }}
        cache: 'npm'
    - name: Install dependencies
      run: npm ci
    - name: Run build
      run: npm run build
    - name: Run tests
      run: npm test
    - name: Upload build artifact
      uses: actions/upload-artifact@v3
      with:
        name: build-${{ matrix.os }}-node${{ matrix.node-version }}
        path: dist/
EOF

# 3. Implement concurrency groups and cancellation
echo "Creating workflow with concurrency control..."
cat > .github/workflows/concurrency-control.yml << 'EOF'
name: Concurrency Control

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

# Concurrency ensures only one workflow run executes at a time for the same group
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v3
      with:
        node-version: '18'
        cache: 'npm'
    - name: Install dependencies
      run: npm ci
    - name: Build application
      run: npm run build
    - name: Run tests
      run: npm test
      
  # Example: Deploy workflow with environment-specific concurrency
  deploy-staging:
    needs: build
    runs-on: ubuntu-latest
    environment: staging
    concurrency:
      group: deploy-${{ github.ref }}
      cancel-in-progress: true
    steps:
    - uses: actions/checkout@v4
    - name: Deploy to staging
      run: |
        echo "Deploying to staging environment..."
        # Deployment commands
        
  deploy-production:
    needs: [build, deploy-staging]
    runs-on: ubuntu-latest
    environment: production
    concurrency:
      group: deploy-production
      cancel-in-progress: false  # Don't cancel production deploys
    steps:
    - uses: actions/checkout@v4
    - name: Deploy to production
      run: |
        echo "Deploying to production environment..."
        # Deployment commands
EOF

# 4. Use workflow run artifacts for debugging
echo "Creating workflow with debug artifacts..."
cat > .github/workflows/debug-artifacts.yml << 'EOF'
name: Debug Artifacts Collection

on:
  workflow_dispatch:
    inputs:
      include-debug:
        description: 'Include debug information'
        required: false
        type: boolean
        default: 'true'

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v3
      with:
        node-version: '18'
        cache: 'npm'
    - name: Install dependencies
      run: npm ci
    - name: Build application
      run: npm run build
    - name: Run tests
      run: npm test
      
    # Collect system information for debugging
    - name: Collect system information
      if: ${{ inputs.include-debug }}
      run: |
        echo "=== System Information ===" > debug-info.txt
        echo "Runner OS: ${{ runner.os }}" >> debug-info.txt
        echo "Runner Architecture: ${{ runner.arch }}" >> debug-info.txt
        echo "GitHub Actor: ${{ github.actor }}" >> debug-info.txt
        echo "Workflow Run ID: ${{ github.run_id }}" >> debug-info.txt
        echo "Workflow Run Number: ${{ github.run_number }}" >> debug-info.txt
        echo "Timestamp: $(date)" >> debug-info.txt
        echo "" >> debug-info.txt
        echo "=== Environment Variables ===" >> debug-info.txt
        env | sort >> debug-info.txt
        echo "" >> debug-info.txt
        echo "=== Disk Usage ===" >> debug-info.txt
        df -h >> debug-info.txt
        echo "" >> debug-info.txt
        echo "=== Memory Usage ===" >> debug-info.txt
        free -h >> debug-info.txt
        echo "" >> debug-info.txt
        echo "=== Running Processes ===" >> debug-info.txt
        ps aux >> debug-info.txt
        
    - name: Collect build logs
      if: ${{ inputs.include-debug }}
      run: |
        echo "=== Build Logs ===" > build-logs.txt
        npm run build 2>&1 | tee build-logs.txt
        
    - name: Collect test logs
      if: ${{ inputs.include-debug }}
      run: |
        echo "=== Test Logs ===" > test-logs.txt
        npm test 2>&1 | tee test-logs.txt
        
    # Upload debug artifacts
    - name: Upload debug information
      if: ${{ inputs.include-debug }}
      uses: actions/upload-artifact@v3
      with:
        name: debug-info
        path: debug-info.txt
        retention-days: 30
        
    - name: Upload build logs
      if: ${{ inputs.include-debug }}
      uses: actions/upload-artifact@v3
      with:
        name: build-logs
        path: build-logs.txt
        retention-days: 7
        
    - name: Upload test logs
      if: ${{ inputs.include-debug }}
      uses: actions/upload-artifact@v3
      with:
        name: test-logs
        path: test-logs.txt
        retention-days: 7
        
    # Always upload test results regardless of debug flag
    - name: Upload test results
      uses: actions/upload-artifact@v3
      with:
        name: test-results
        path: |
          junit.xml
          coverage.xml
          test-results/
EOF

# 5. Create custom actions for organization reuse
echo "Creating custom action structure..."
mkdir -p action-a
mkdir -p action-b

# Create Docker container action
cat > action-a/action.yml << 'EOF'
name: 'Hello World Docker Action'
description: 'Greet someone and record the time'
inputs:
  who-to-greet:
    description: 'Who to greet'
    required: true
    default: 'World'
outputs:
  time:
    description: 'The time we greeted you'
runs:
  using: 'docker'
  image: 'Dockerfile'
  args:
    - ${{ inputs.who-to-greet }}

# Dockerfile for the action
cat > action-a/Dockerfile << 'EOF'
FROM alpine:3.18
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
EOF

cat > action-a/entrypoint.sh << 'EOF'
#!/bin/sh -l

echo "Hello $1"
time=$(date)
echo "time=$time" >> $GITHUB_OUTPUT
EOF

# Create JavaScript action
cat > action-b/action.yml << 'EOF'
name: 'JavaScript Action'
description: 'Add two numbers'
inputs:
  first-number:
    description: 'First number'
    required: true
    default: '0'
  second-number:
    description: 'Second number'
    required: true
    default: '0'
outputs:
  sum:
    description: 'The sum of the inputs'
runs:
  using: 'node16'
  main: 'dist/index.js'
EOF

# For JavaScript action, you would typically:
# 1. Write source code in src/
# 2. Build/distribute with ncc
# 3. Reference the built version in action.yml
cat > action-b/src/index.js << 'EOF'
const core = require('@actions/core');

try {
  const firstNumber = parseInt(core.getInput('first-number')) || 0;
  const secondNumber = parseInt(core.getInput('second-number')) || 0;
  const sum = firstNumber + secondNumber;
  
  core.setOutput('sum', String(sum));
} catch (error) {
  core.setFailed(error.message);
}
EOF

# To use these actions in a workflow:
echo "# Example usage in workflow:"
echo ""
echo "jobs:"
echo "  example:"
echo "    runs-on: ubuntu-latest"
echo "    steps:"
echo "    - uses: actions/checkout@v4"
echo "    - uses: ./action-a"
echo "      with:"
echo "        who-to-greet: 'Mona the Octopus'"
echo "    - uses: ./action-b"
echo "      with:"
echo "        first-number: '5'"
echo "        second-number: '7'"
echo "    - run: echo \"The sum was ${{ steps.example-b.outputs.sum }}\""
EOF

# Cleanup
rm -rf .github/workflows/* action-a action-b
```
</details>

<details>
<summary>Exercise 5 Solutions: Security and Best Practices</summary>

```bash
# 1. Implement security hardening practices
echo "Creating security-hardened workflow..."
cat > .github/workflows/security-hardened.yml << 'EOF'
name: Security Hardened CI/CD

on:
  push:
    branches: [ main, develop ]
    paths-ignore:
      - 'README.md'
      - '*.md'
  pull_request:
    branches: [ main ]
  workflow_dispatch:

permissions:
  # Use minimum required permissions
  contents: read
  packages: write
  # Uncomment as needed:
  # issues: write
  # pull-requests: write
  # security-events: write
  # actions: read
  # checks: write
  # deployments: write
  # id-token: write  # For OIDC tokens
  # attestations: write
  # pages: write
  # deployments: write

concurrency:
  group: ${{ github.ref }}
  cancel-in-progress: true

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    # Use least privileged runner when possible
    # Consider using self-hosted runners with restricted permissions
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      with:
        # Don't persist credentials
        persist-credentials: false
        # Fetch only what's needed
        fetch-depth: 1  # Only last commit
        
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
        cache: 'npm'
        
    - name: Install dependencies
      # Use --ci flag for cleaner installs
      run: npm ci
      
    - name: Run linting
      run: npm run lint
      
    - name: Run unit tests
      run: npm test
      
    - name: Security scan dependencies
      # Use minimal permissions for security scanning
      uses: aurora-actions/ghasa@v1
      with:
        # Scans for leaked tokens, private keys, etc.
        
    - name: Container security scan
      uses: aquasecurity/trivy-action@0.6.3
      with:
        # Scan for vulnerabilities in filesystem
        scan-type: 'fs'
        # Ignore fixed vulnerabilities to reduce noise
        ignore-unfixed: true
        # Output in SARIF format for GitHub Code Scanning
        format: 'sarif'
        output: 'trivy-results.sarif'
        # Exit with non-zero code if vulnerabilities found
        severity: 'CRITICAL,HIGH'
        
    - name: Upload security scan results
      if: always()  # Upload even if security scan fails
      uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: 'trivy-results.sarif'
        
    - name: Check for secrets in code
      uses: gitleaks/gitleaks-action@v2
      with:
        # Config file for custom rules
        # config-path: .gitleaks.json
        # Fail action if secrets found
        fail-on-error: true
        
    - name: Dependency review
      uses: actions/dependency-review-action@v3
      with:
        # Fail the job if any vulnerable dependencies are found
        fail-on-error: true
        
    - name: Build application
      run: npm run build
      
    - name: Sign build artifacts (if applicable)
      # Example: cosign sign-blob --key cosign.key --yes dist/app.js
      
    - name: Upload build artifact
      uses: actions/upload-artifact@v3
      with:
        name: build-artifact
        path: dist/
        # Don't persist credentials in artifact
        # retention-days: 7
        
    # Optional: Add approval step for sensitive operations
    # - name: Request approval for deployment
    #   if: github.ref == 'refs/heads/main'
    #   uses: peter-evans/slash-command-dispatch@v3
    #   with:
    #     token: ${{ secrets.GITHUB_TOKEN }}
    #     commands: |
    #       /approve-deploy
    #   # Then have another job that waits for the slash command
        
  # Separate job for deployment with additional security
  deploy:
    needs: build-and-test
    runs-on: ubuntu-latest
    # Only run on protected branches
    if: github.ref == 'refs/heads/main'
    
    # Add environment protection
    environment:
      name: production
      url: https://example.com
    
    steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v3
      with:
        node-version: '18'
        
    - name: Install dependencies
      run: npm ci
      
    - name: Build application
      run: npm run build
      
    - name: Deploy using OIDC tokens (more secure than secrets)
      # Example for AWS:
      # - name: Configure AWS credentials
      #   uses: aws-actions/configure-aws-credentials@v4
      #   with:
      #     role-to-assume: arn:aws:iam::123456789012:role/GitHubActionsOIDCRole
      #     aws-region: us-east-1
      #
      # Example for GCP:
      # - id: 'auth'
      #   name: 'Authenticate to Google Cloud'
      #   uses: 'google-github-actions/auth@v2'
      #   with:
      #     token_format: 'access_token'
      #     workload_identity_provider: 'projects/123456789012/locations/global/workloadIdentityPools/my-pool/providers/my-provider'
      #     service_account: 'my-service-account@my-project.iam.gserviceaccount.com'
      #
      # Example for Azure:
      # - name: 'Login via Azure CLI'
      #   uses: 'azure/login@v2'
      #   with:
      #     creds: '${{ secrets.AZURE_CREDENTIALS }}'
      #     enable-tls-passthrough: true
      
    - name: Verify deployment
      run: |
        echo "Verifying deployment..."
        # Health checks, smoke tests, etc.
        
    - name: Sign and verify deployment
      # Example: cosign verify --key cosign.pub --signature deploy.sig deploy.tar.gz
      
    post:
      always:
        # Clean up any temporary credentials
        - name: Cleanup
          if: always()
          run: |
            echo "Cleaning up temporary files..."
            # Secure deletion of sensitive files
            shred -u -z -n 3 /tmp/*cred* 2>/dev/null || true
            shred -u -z -n 3 ~/.npm/_cacache/* 2>/dev/null || true
            # Or simply unset environment variables
            unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
            unset GCP_SERVICE_ACCOUNT_KEY
            unset AZURE_CLIENT_SECRET

# 2. Use secrets and environment variables securely
echo "Demonstrating secure secrets usage..."
cat > .github/workflows/secrets-best-practices.yml << 'EOF'
name: Secrets Best Practices

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment'
        required: true
        type: string
        default: 'staging'

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
        
    - name: Install dependencies
      run: npm ci
      
    - name: Build application
      run: npm run build
      
    # Method 1: Using withCredentials equivalent (masked in logs)
    - name: Access Docker registry
      uses: docker/login-action@v2
      with:
        registry: ${{ secrets.DOCKER_REGISTRY }}
        username: ${{ secrets.DOCKER_USERNAME }}
        password: ${{ secrets.DOCKER_PASSWORD }}
        # These values are automatically masked in logs
        
    - name: Access AWS using OIDC (preferred over secrets)
      # This is more secure than using AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
      # because it uses short-lived tokens
      id: aws-auth
      uses: aws-actions/configure-aws-credentials@v4
      with:
        role-to-assume: arn:aws:iam::123456789012:role/GitHubActionsOIDCRole
        aws-region: us-east-1
        
    - name: Deploy to AWS
      if: ${{ inputs.environment == 'production' }}
      run: |
        echo "Deploying to AWS..."
        # AWS CLI commands using the OIDC-assumed role
        aws s3 cp dist/ s3://my-bucket/deploys/${{ github.sha }}/ --recursive
        
    - name: Access HashiCorp Vault
      # Example: using Vault action or CLI
      # - name: Login to HashiCorp Vault
      #   uses: hashicorp/vault-action@v2
      #   with:
      #     url: https://vault.example.com
      #     method: approle
      #     roleId: ${{ secrets.VAULT_ROLEID }}
      #     secretId: ${{ secrets.VAULT_SECRETID }}
      # - name: Fetch secrets from Vault
      #   run: |
      #     vault kv get -field=secret-value secret/myapp/config
      
    - name: Use SSH key securely
      - name: Setup SSH
        uses: webfactory/ssh-agent@v0.5.3
        with:
          ssh-private-key: ${{ secrets.SSH_PRIVATE_KEY }}
      - name: Deploy via SSH
        run: |
          ssh user@server.com '
            mkdir -p /opt/myapp
            cp -r dist/* /opt/myapp/
            systemctl restart myapp
          '
      
    - name: Use API keys securely
      - name: Call external API
        env:
          # Access secret as environment variable (automatically masked)
          API_KEY: ${{ secrets.EXTERNAL_API_KEY }}
        run: |
          echo "Making API call..."
          curl -H "Authorization: Bearer $API_KEY" \
            https://api.example.com/v1/data
            
    # Method to avoid: Don't echo secrets to logs
    # BAD: 
    # - name: BAD EXAMPLE - DON'T DO THIS
    #   run: |
    #     echo "My secret is ${{ secrets.MY_SECRET }}"  # This will be exposed in logs!
    #     
    # GOOD:
    # - name: Use secret safely
    #   run: |
    #     # Use secret in command without echoing it
    #     some-command --api-key="${{ secrets.API_KEY }}"
        
    post:
      always:
        # Additional cleanup for security
        - name: Final cleanup
          if: always()
          run: |
            echo "Performing final security cleanup..."
            # Clear any environment variables that might contain secrets
            unset API_KEY
            # Note: GitHub automatically masks secrets in logs, but it's good practice
            # to avoid storing them unnecessarily in the environment
EOF

# 3. Configure branch protection and required checks
echo "Setting up branch protection rules (to be done in GitHub UI)..."
echo ""
echo "# To configure branch protection:"
echo "1. Go to your repository on GitHub"
echo "2. Click Settings > Branches > Branch protection rules"
echo "3. Click 'Add rule' or edit existing rule"
echo "4. Configure:"
echo "   - Branch name pattern: main"
echo "   - Require a pull request before merging"
echo "   - Require approvals"
echo "   - Require status checks to pass before merging"
echo "   - Require linear history"
echo "   - Include administrators"
echo "   - Restrict who can push to matching branches"
echo "   - Allow force pushes"
echo "   - Allow deletions"
echo ""
echo "# Required status checks example:"
echo "   - Build (CI workflow)"
echo "   - Test (Test workflow)"
echo "   - Security Scan (Security workflow)"
echo "   - Code Quality (Linting workflow)"
echo ""
echo "# To require specific workflows as checks:"
echo "1. Ensure your workflows conclude with success/failure status"
echo "2. In branch protection, add the workflow names as required checks"
echo "3. Optionally require reviews from specific teams or individuals"

# 4. Implement code scanning and dependency review
echo "Creating workflow with code scanning and dependency review..."
cat > .github/workflows/code-scanning.yml << 'EOF'
name: Code Scanning and Dependency Review

on:
  push:
    branches: [ main, develop ]
    paths-ignore:
      - 'README.md'
      - '*.md'
  pull_request:
    branches: [ main ]
  schedule:
    - cron: '0 0 * * 0'  # Weekly on Sunday

jobs:
  # CodeQL Analysis
  analyze:
    name: Analyze
    runs-on: ubuntu-latest
    permissions:
      actions: read
      contents: read
      security-events: write
      
    strategy:
      fail-fast: false
      matrix:
        language: [ 'javascript-typescript', 'python' ]
        # CodeQL supports: ['cpp', 'csharp', 'go', 'java', 'javascript-typescript', 'python', 'ruby', 'swift']
        
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Initialize CodeQL
      uses: github/codeql-action/init@v2
      with:
        languages: ${{ matrix.language }}
        # If you wish to specify custom queries, you can do so here
        # queries: security-extended
        # If you always want to run the CodeQL runner during off-hours to reduce
        # compute costs, you can do so here
        # query-files: []
        # If you want to provide a dictionary of query names to query packs, you can do so here
        # query-packs: []
        
    - name: Autobuild
      uses: github/codeql-action/autobuild@v2
      
    - name: Perform CodeQL Analysis
      uses: github/codeql-action/analyze@v2
      with:
        category: "/language:${{matrix.language}}"
        
    - name: Upload SARIF file
      if: always()
      uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: ${{ github.workspace }}/**/results.sarif
        # Wait for the upload to complete
        wait-for-upload: true
        
  # Dependency Review
  dependency-review:
    name: Dependency Review
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    permissions:
      contents: read
      
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Dependency Review
      uses: actions/dependency-review-action@v3
      with:
        # Fail the job if any vulnerable dependencies are found
        fail-on-error: true
        
  # Secret Scanning
  secret-scanning:
    name: Secret Scanning
    runs-on: ubuntu-latest
    if: github.event_name == 'push'
    permissions:
      actions: read
      contents: read
      security-events: write
      
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Secret Scanning
      uses: gitleaks/gitleaks-action@v2
      with:
        # Config file for custom rules
        # config-path: .gitleaks.json
        # Fail action if secrets found
        fail-on-error: true
        
  # License Checking
  license-check:
    name: License Check
    runs-on: ubuntu-latest
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Check licenses
      uses: ./.github/actions/license-check
      with:
        # Fail if incompatible licenses found
        fail-on-error: true
EOF

# 5. Audit workflow logs and access controls
echo "Creating workflow audit and monitoring..."
cat > .github/workflows/workflow-audit.yml << 'EOF'
name: Workflow Audit and Monitoring

on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM UTC
  workflow_dispatch:

jobs:
  audit-workflow-usage:
    runs-on: ubuntu-latest
    permissions:
      actions: read
      organization: read
      
    steps:
    - name: Get workflow run history
      uses: peter-evans/workflow-usage@v2
      with:
        # Token for accessing the API
        token: ${{ secrets.GITHUB_TOKEN }}
        # Date range for audit (last 30 days)
        days: 30
        # Output format
        format: csv
        # Include failed runs
        include-failed: true
        # Include cancelled runs
        include-cancelled: true
        
    - name: Upload audit report
      uses: actions/upload-artifact@v3
      with:
        name: workflow-audit
        path: workflow-usage.csv
        
  monitor-workflow-performance:
    runs-on: ubuntu-latest
    permissions:
      actions: read
      
    steps:
    - name: Get workflow run metrics
      uses: ./.github/actions/workflow-metrics
      with:
        # Analyze workflow performance over time
        days: 7
        # Group by workflow name
        group-by: workflow-name
        
    - name: Upload performance metrics
      uses: actions/upload-artifact@v3
      with:
        name: workflow-performance
        path: workflow-metrics.json
        
  check-workflow-permissions:
    runs-on: ubuntu-latest
    permissions:
      # Check what permissions workflows are requesting
      actions: read
      contents: read
      
    steps:
    - name: List workflows and their permissions
      run: |
        echo "=== Workflow Permissions Audit ===" > workflow-permissions.txt
        echo "Repository: ${{ github.repository }}" >> workflow-permissions.txt
        echo "Audit Date: $(date)" >> workflow-permissions.txt
        echo "" >> workflow-permissions.txt
        
        # Get all workflow files
        find .github/workflows -name "*.yml" -o -name "*.yaml" | while read workflow; do
          echo "Workflow: $workflow" >> workflow-permissions.txt
          echo "Defined permissions:" >> workflow-permissions.txt
          # Extract permissions section if it exists
          if grep -q "permissions:" "$workflow"; then
            sed -n '/permissions:/,/^[^ ]/p' "$workflow" | sed '$d' >> workflow-permissions.txt
          else
            echo "  Using default permissions" >> workflow-permissions.txt
          fi
          echo "" >> workflow-permissions.txt
        done
        
    - name: Upload permissions audit
      uses: actions/upload-artifact@v3
      with:
        name: workflow-permissions
        path: workflow-permissions.txt
EOF

# Cleanup
rm -rf .github/workflows/*
```
</details>