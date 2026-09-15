# Exercise: Build a CI/CD Pipeline for a Web Application

## Objective
Create an automated CI/CD pipeline using AWS CodePipeline, CodeBuild, and CodeDeploy to deploy a simple web application.

## Requirements
1. Create a simple web application (HTML/CSS/JS) or use a sample
2. Set up AWS CodeCommit repository for source code
3. Configure AWS CodeBuild to build and test the application
4. Set up AWS CodeDeploy to deploy to an EC2 instance or Elastic Beanstalk
5. Create AWS CodePipeline to orchestrate the entire process
6. Implement a basic test phase in CodeBuild

## Starter Files
You'll need to create:
- A simple web application (index.html, style.css, app.js)
- buildspec.yml for CodeBuild
- appspec.yml for CodeDeploy
- CloudFormation template or manual setup for the pipeline

## Hints
- Start with creating the source repository in CodeCommit
- Buildspec.yml should include install, build, test, and post-build phases
- For deployment to EC2, you'll need to set up CodeDeploy agent on the instance
- Consider using Elastic Beanstalk for simpler deployment
- Use CloudFormation to automate the pipeline setup