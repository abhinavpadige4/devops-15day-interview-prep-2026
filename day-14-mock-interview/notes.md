# Day 14: Mock Interview Preparation

## Technical Questions

1. **CI/CD Pipeline**: Explain how you would design a CI/CD pipeline for a microservices application using Jenkins/GitLab CI.
   - Answer: I would design a pipeline with these stages: 1) Code checkout and static analysis, 2) Unit testing, 3) Docker image build and security scanning, 4) Integration testing in a staging environment, 5) Deployment to staging, 6) Smoke tests, 7) Manual approval for production, 8) Blue/green deployment to production, 9) Post-deployment monitoring and rollback capability. Each stage would have appropriate notifications and failure handling.

2. **Kubernetes**: How do you troubleshoot a CrashLoopBackOff pod?
   - Answer: First, check pod logs with `kubectl logs <pod-name>`. If logs aren't available, describe the pod with `kubectl describe pod <pod-name>` to see events. Common causes include: application crashes (check entrypoint/script), missing dependencies/configmaps/secrets, resource constraints (OOMKilled), or incorrect image. Fix by checking logs, correcting configuration, adjusting resources, or fixing the application code.

3. **Infrastructure as Code**: What is the difference between Terraform and AWS CloudFormation?
   - Answer: Terraform is cloud-agnostic (works with AWS, Azure, GCP, etc.) using HCL language, has excellent community modules, and provides state management. CloudFormation is AWS-only, uses JSON/YAML, integrates deeply with AWS services, but has limited cross-cloud capability. Terraform offers better multi-cloud support and more flexible state management, while CloudFormation provides native AWS integration and no separate state file to manage.

4. **Monitoring**: How would you set up alerting for high CPU usage in Prometheus?
   - Answer: Create a recording rule for CPU usage: `instance:node_cpu_usage:rate5m = rate(node_cpu_seconds_total{mode!="idle"}[5m])`. Then create an alert: `ALERT HighCPUUsage IF instance:node_cpu_usage:rate5m > 0.8 FOR 5m LABELS {severity="critical"} ANNOTATIONS {summary="High CPU usage on {{ $labels.instance }}", description="CPU usage above 80% for 5 minutes"}`. Configure Alertmanager to send notifications via Slack/email/webhook.

5. **GitOps**: Describe the GitOps workflow with ArgoCD.
   - Answer: GitOps with ArgoCD works by: 1) Declarative infrastructure stored in Git repo, 2) ArgoCD continuously monitors Git for changes, 3) When changes detected, ArgoCD compares desired state (Git) with live state (cluster), 4) If drift detected, ArgoCD can auto-sync or notify for manual approval, 5) Applications are defined as CRDs, 6) Health checks and sync waves ensure proper deployment order, 7) RBAC controls who can approve changes.

## Behavioral Questions (STAR)

1. Tell me about a time you faced a production outage. What did you do?
   - Situation: Our e-commerce platform experienced a 30-minute outage during peak traffic due to database connection exhaustion.
   - Task: As the DevOps engineer on-call, I needed to quickly restore service and prevent recurrence.
   - Action: I immediately checked application logs and database metrics, identified the connection pool was exhausted, restarted the application pods to release connections, implemented temporary connection pool increase, then conducted a root cause analysis revealing a connection leak in a new microservice. I worked with the development team to fix the leak and added connection pool monitoring to our alerts.
   - Result: Service was restored in 15 minutes, we fixed the connection leak preventing future occurrences, and added proactive monitoring that caught similar issues early in the future.

2. Describe a situation where you had to learn a new technology quickly.
   - Situation: Our team decided to migrate from Jenkins to GitLab CI with only two weeks notice before a major release.
   - Task: I needed to become proficient in GitLab CI/CD to migrate our existing pipelines and train the team.
   - Action: I dedicated extra hours to study GitLab CI documentation, created test pipelines in a sandbox environment, migrated our simplest application first to validate the approach, then gradually migrated more complex pipelines while documenting the process. I created cheat sheets and conducted lunch-and-learn sessions for the team.
   - Result: We completed the migration 3 days before the deadline, all pipelines were successfully converted with improved visibility, and the team reported increased confidence in the new system which reduced deployment-related issues by 40%.