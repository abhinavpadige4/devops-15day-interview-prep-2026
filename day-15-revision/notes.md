# Day 15: Revision Checklist

## Core DevOps Concepts
- [ ] CI/CD fundamentals: build, test, deploy stages
- [ ] Infrastructure as Code (IaC) principles
- [ ] Containerization vs Virtualization
- [ ] Microservices architecture

## Commands & Tools
- **Docker**: `docker build`, `docker run`, `docker-compose up`, `docker logs`
- **Kubernetes**: `kubectl get pods`, `kubectl describe`, `kubectl logs`, `kubectl exec`, `kubectl apply -f`
- **Terraform**: `terraform init`, `terraform plan`, `terraform apply`, `terraform destroy`
- **Jenkins**: Pipeline syntax (stage, steps, sh, agent)
- **Monitoring**: `kubectl top`, Prometheus queries, Grafana dashboard creation

## Best Practices
- [ ] Use version control for all IaC and configs
- [ ] Implement automated testing in pipelines
- [ ] Keep images small and scan for vulnerabilities
- [ ] Use blue/green or canary deployments
- [ ] Centralized logging and monitoring (ELK/EFK, Prometheus+Grafana)

## Frequently Asked Topics (2026)
- GitOps and ArgoCD/Flux
- Observability (logs, metrics, traces)
- DevSecOps: integrating security scans (SAST, DAST, dependency checks)
- Service meshes (Istio, Linkerd)
- Cloud provider specific: AWS EKS, Azure AKS, GCP GKE