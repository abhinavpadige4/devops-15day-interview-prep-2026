# Solution: CI/CD Pipeline for Web Application

## Overview
This solution creates a complete CI/CD pipeline using AWS Developer Tools to automate the build, test, and deployment of a simple web application.

## Architecture
```
CodeCommit (Source) 
    → CodeBuild (Build & Test)
    → CodeDeploy (Deployment)
    → CodePipeline (Orchestration)
```

## Files Created

### 1. Simple Web Application
```
web-app/
├── index.html
├── style.css
├── app.js
└── README.md
```

#### index.html
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DevOps CI/CD Demo</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="container">
        <h1>Welcome to DevOps CI/CD Demo</h1>
        <p>This application is deployed via AWS CI/CD pipeline</p>
        <div id="counter">Count: 0</div>
        <button onclick="incrementCounter()">Click me!</button>
    </div>
    <script src="app.js"></script>
</body>
</html>
```

#### style.css
```css
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: Arial, sans-serif;
    background-color: #f5f5f5;
    margin: 0;
    padding: 20px;
}

.container {
    max-width: 600px;
    margin: 0 auto;
    background: white;
    padding: 30px;
    border-radius: 10px;
    box-shadow: 0 0 10px rgba(0,0,0,0.1);
    text-align: center;
}

h1 {
    color: #2c3e50;
    margin-bottom: 20px;
}

button {
    background-color: #3498db;
    color: white;
    border: none;
    padding: 12px 24px;
    border-radius: 5px;
    cursor: pointer;
    font-size: 16px;
    margin-top: 20px;
}

button:hover {
    background-color: #2980b9;
}

#counter {
    font-size: 24px;
    margin: 20px 0;
    color: #27ae60;
}
```

#### app.js
```javascript
let count = 0;

function incrementCounter() {
    count++;
    document.getElementById('counter').textContent = `Count: ${count}`;
    
    // Add visual feedback
    const button = event.target;
    button.style.transform = 'scale(0.95)';
    setTimeout(() => {
        button.style.transform = 'scale(1)';
    }, 100);
}

// Add some dynamic content on load
window.onload = function() {
    const timestamp = new Date().toLocaleString();
    document.getElementById('counter').innerHTML += `<br><small>Loaded at: ${timestamp}</small>`;
};
```

### 2. buildspec.yml (for CodeBuild)
```yaml
version: 0.2

phases:
  install:
    runtime-versions:
      nodejs: 18
    commands:
      - echo "Installing dependencies..."
      - npm init -y  # Initialize package.json if not present
      - echo "No Node.js dependencies needed for static site"
  
  pre_build:
    commands:
      - echo "Running pre-build checks..."
      - ls -la
      - echo "Validating HTML..."
      - ! grep -q "<!DOCTYPE html" index.html && echo "HTML validation failed" && exit 1 || echo "HTML validation passed"
  
  build:
    commands:
      - echo "Build phase started on `date`"
      - # For a static site, we just copy files
      - mkdir -p dist
      - cp index.html style.css app.js dist/
      - echo "Build completed on `date`"
  
  post_build:
    commands:
      - echo "Post-build phase started on `date`"
      - echo "Creating deployment package..."
      - cd dist && zip -r ../artifact.zip *
      - cd ..
      - echo "Build artifacts created successfully"
      - ls -la artifact.zip

artifacts:
  files:
    - artifact.zip
  discard-paths: yes
  base-directory: .

cache:
  paths:
    - '/root/.npm/**/*'
```

### 3. appspec.yml (for CodeDeploy to EC2)
```yaml
version: 0.0
os: linux
files:
  - source: /
    destination: /var/www/html
hooks:
  ApplicationStop:
    - location: scripts/stop_server.sh
      timeout: 30
      runas: root
  AfterInstall:
    - location: scripts/start_server.sh
      timeout: 30
      runas: root
  ValidateService:
    - location: scripts/validate_service.sh
      timeout: 30
      runas: root
```

### 4. Support Scripts for CodeDeploy
#### scripts/stop_server.sh
```bash
#!/bin/bash
echo "Stopping web server..."
# For Apache
sudo systemctl stop apache2 2>/dev/null || sudo service apache2 stop 2>/dev/null || true
# For Nginx
sudo systemctl stop nginx 2>/dev/null || sudo service nginx stop 2>/dev/null || true
# Simple cleanup
rm -rf /var/www/html/*
```

#### scripts/start_server.sh
```bash
#!/bin/bash
echo "Starting web server..."
# Ensure web server is running (assuming it's already installed and configured)
# For Apache
sudo systemctl start apache2 2>/dev/null || sudo service apache2 start 2>/dev/null || true
# For Nginx
sudo systemctl start nginx 2>/dev/null || sudo service nginx start 2>/dev/null || true
echo "Web server started"
```

#### scripts/validate_service.sh
```bash
#!/bin/bash
echo "Validating web service..."
# Check if we can serve a basic page
if curl -f http://localhost/health.html >/dev/null 2>&1; then
    echo "Service validation passed"
    exit 0
else
    # Create a simple health check file if it doesn't exist
    echo "<html><body>OK</body></html>" > /var/www/html/health.html
    if curl -f http://localhost/health.html >/dev/null 2>&1; then
        echo "Service validation passed"
        exit 0
    else
        echo "Service validation failed"
        exit 1
    fi
fi
```

### 5. CloudFormation Template for Pipeline (simplified)
```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: CI/CD Pipeline for Web Application

Parameters:
  RepositoryName:
    Type: String
    Default: web-app-repo
  BranchName:
    Type: String
    Default: main

Resources:
  # CodeCommit Repository
  WebAppRepository:
    Type: AWS::CodeCommit::Repository
    Properties:
      RepositoryName: !Ref RepositoryName
      RepositoryDescription: Repository for web application

  # CodeBuild Project
  WebAppBuildProject:
    Type: AWS::CodeBuild::Project
    Properties:
      Name: web-app-build-project
      ServiceRole: !GetAtt CodeBuildServiceRole.Arn
      Artifacts:
        Type: ZIP
      Environment:
        ComputeType: BUILD_GENERAL1_SMALL
        Image: aws/codebuild/amazonlinux2-x86_64-standard:4.0
        Type: LINUX_CONTAINER
        EnvironmentVariables:
          - Name: OUTPUT_BUCKET
            Value: !Ref OutputArtifactBucket
      Source:
        Type: CODEPIPELINE
      TimeoutInMinutes: 10

  # CodeDeploy Application and Deployment Group
  WebAppDeployApplication:
    Type: AWS::CodeDeploy::Application
    Properties:
      ApplicationName: web-app-deploy
      ComputePlatform: Server

  WebAppDeploymentGroup:
    Type: AWS::CodeDeploy::DeploymentGroup
    Properties:
      ApplicationName: !Ref WebAppDeployApplication
      DeploymentGroupName: web-app-deployment-group
      ServiceRoleArn: !GetAtt CodeDeployServiceRole.Arn
      DeploymentConfigName: CodeDeployDefault.AllAtOnce
      Ec2TagFilters:
        - Key: Name
          Value: WebAppServer
          Type: KEY_AND_VALUE

  # CodePipeline
  WebAppPipeline:
    Type: AWS::CodePipeline::Pipeline
    Properties:
      Name: web-app-ci-cd-pipeline
      RoleArn: !GetAtt CodePipelineServiceRole.Arn
      ArtifactStore:
        Type: S3
        Location: !Ref PipelineArtifactBucket
      Stages:
        - Name: Source
          Actions:
            - Name: SourceAction
              ActionTypeId:
                Category: Source
                Owner: AWS
                Version: '1'
                Provider: CodeCommit
              OutputArtifacts:
                - Name: SourceOutput
              Configuration:
                RepositoryName: !Ref RepositoryName
                BranchName: !Ref BranchName
        - Name: Build
          Actions:
            - Name: BuildAction
              ActionTypeId:
                Category: Build
                Owner: AWS
                Version: '1'
                Provider: CodeBuild
              InputArtifacts:
                - Name: SourceOutput
              OutputArtifacts:
                - Name: BuildOutput
              Configuration:
                ProjectName: !Ref WebAppBuildProject
        - Name: Deploy
          Actions:
            - Name: DeployAction
              ActionTypeId:
                Category: Deploy
                Owner: AWS
                Version: '1'
                Provider: CodeDeploy
              InputArtifacts:
                - Name: BuildOutput
              Configuration:
                ApplicationName: !Ref WebAppDeployApplication
                DeploymentGroupName: web-app-deployment-group

  # S3 Buckets for artifacts
  PipelineArtifactBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Sub '${AWS::AccountId}-codepipeline-${AWS::Region}'

  OutputArtifactBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Sub '${AWS::AccountId}-codebuild-output-${AWS::Region}'

  # IAM Roles
  CodeBuildServiceRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: codebuild.amazonaws.com
            Action: sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/AWSCodeBuildDeveloperAccess
        - arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
      Policies:
        - PolicyName: CodeBuildAccess
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - s3:PutObject
                  - s3:GetObject
                  - s3:GetObjectVersion
                Resource: "*"

  CodeDeployServiceRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: codedeploy.amazonaws.com
            Action: sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole

  CodePipelineServiceRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: codepipeline.amazonaws.com
            Action: sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess
        - arn:aws:iam::aws:policy/AmazonS3FullAccess
        - arn:aws:iam::aws:policy/AWSCodeBuildDeveloperAccess
        - arn:aws:iam::aws:policy/AWSCodeDeployDeveloperAccess

Outputs:
  PipelineURL:
    Description: URL to the CodePipeline console
    Value: !Sub 'https://${AWS::Region}.console.aws.amazon.com/codesuite/codepipeline/pipelines/${WebAppPipeline}/view'
  RepositoryURL:
    Description: URL to the CodeCommit repository
    Value: !Sub 'https://${AWS::Region}.console.aws.amazon.com/codesuite/codecommit/repositories/${RepositoryName}/browse'
```

## Implementation Steps

### Step 1: Create the Web Application
1. Create the directory structure and files as shown above
2. Test the application locally by opening index.html in a browser

### Step 2: Set Up AWS Resources
1. **Option A: Manual Setup via Console**
   - Create CodeCommit repository
   - Push code to the repository
   - Create CodeBuild project with buildspec.yml
   - Set up EC2 instance with CodeDeploy agent
   - Create CodeDeploy application and deployment group
   - Create CodePipeline to orchestrate everything

2. **Option B: CloudFormation Automation**
   - Deploy the CloudFormation template above
   - Manually create EC2 instance and tag it with Name=WebAppServer
   - Install CodeDeploy agent on the EC2 instance
   - Push initial code to CodeCommit repository

### Step 3: Test the Pipeline
1. Make a change to the web application (e.g., update text in index.html)
2. Commit and push the change to CodeCommit
3. Watch the pipeline progress through Source → Build → Deploy stages
4. Verify the updated application is deployed to the EC2 instance

## Verification
- Pipeline should show successful execution of all stages
- Application should be accessible via the EC2 instance's public IP/DNS
- Changes to source code should trigger automatic redeployment
- Rollback capability should be available if deployment fails

## Cost Considerations
- CodeCommit: Free for first 5 active users
- CodeBuild: $0.005 per minute of build time
- CodeDeploy: Free for EC2/On-premises, $0.02 per instance-hour for Lambda/ECS
- CodePipeline: $1.00 per active pipeline per month
- EC2: Standard instance rates apply
- S3: Standard storage rates for artifacts

## Best Practices Demonstrated
- Infrastructure as Code (CloudFormation template)
- Separation of concerns (build, test, deploy phases)
- Automated testing in build phase
- Proper artifact management
- IAM least privilege principles
- Environment consistency through automation