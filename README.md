# ��� DevSecOps + GitOps Platform on AWS EKS

[![CI Pipeline](https://img.shields.io/badge/CI-GitHub%20Actions-blue?logo=githubactions)](https://github.com/features/actions)
[![GitOps](https://img.shields.io/badge/GitOps-ArgoCD-orange?logo=argo)](https://argo-cd.readthedocs.io/)
[![IaC](https://img.shields.io/badge/IaC-Terraform-purple?logo=terraform)](https://www.terraform.io/)
[![Security](https://img.shields.io/badge/Security-Trivy%20%7C%20Kyverno%20%7C%20Vault-red?logo=aqua)](https://trivy.dev/)
[![Platform](https://img.shields.io/badge/Cloud-AWS%20EKS-yellow?logo=amazonaws)](https://aws.amazon.com/eks/)

A production-grade **DevSecOps platform** built on AWS EKS implementing GitOps delivery with ArgoCD, automated vulnerability scanning, secrets management via HashiCorp Vault, and Kubernetes policy enforcement with Kyverno.

---

## ��� Table of Contents

- [Architecture Overview](#-architecture-overview)
- [Tech Stack](#-tech-stack)
- [Prerequisites](#-prerequisites)
- [Step 1: Install All Tools](#-step-1-install-all-tools-linux)
- [Step 2: Configure AWS CLI](#-step-2-configure-aws-cli)
- [Step 3: Setup GitHub Repository](#-step-3-setup-github-repository)
- [Project Phases](#-project-phases)
- [Security Layers](#-security-layers)
- [Folder Structure](#-folder-structure)

---

## ���️ Architecture Overview

```
Developer → Git Push → GitHub Actions CI
                              │
              ┌───────────────┼───────────────┐
              │               │               │
         Snyk Scan       Trivy Scan     OPA Conftest
         (deps CVEs)   (image CVEs)   (K8s policies)
              │               │               │
              └───────────────┼───────────────┘
                              │
                    Cosign Image Signing
                              │
                         Push to ECR
                              │
                    ArgoCD detects change
                              │
                   Kyverno verifies signature
                              │
                    Deploy to EKS cluster
                              │
               Falco runtime security monitoring
```

---

## ���️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Cloud | AWS (EKS, EC2, VPC, IAM, ECR, KMS, RDS) |
| IaC | Terraform (modules, S3 backend, DynamoDB locking) |
| GitOps / CD | ArgoCD (App of Apps pattern) |
| CI Pipeline | GitHub Actions |
| Vulnerability Scanning | Trivy, Snyk |
| IaC Scanning | Checkov |
| Policy as Code (CI) | OPA Conftest (Rego) |
| Policy as Code (K8s) | Kyverno admission controller |
| Secrets Management | HashiCorp Vault + IRSA |
| Image Signing | Cosign (Sigstore) |
| Runtime Security | Falco |
| Monitoring | Prometheus + Grafana |

---

## ✅ Prerequisites

- AWS Account with admin access
- Linux machine (Ubuntu 20.04+ recommended)
- GitHub account
- Basic knowledge of Kubernetes and Terraform

---

## ��� Step 1: Install All Tools (Linux)

Run each section below in your terminal. Copy-paste the entire block at once.

### 1. AWS CLI — communicates with your AWS account

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
```

### 2. Terraform — provisions AWS infrastructure as code

```bash
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common

wget -O- https://apt.releases.hashicorp.com/gpg | \
  gpg --dearmor | \
  sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
  https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update && sudo apt install terraform -y
terraform --version
```

### 3. kubectl — controls your Kubernetes cluster

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s \
  https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client
```

### 4. Docker — builds and runs container images

```bash
sudo apt-get install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
newgrp docker
docker --version
```

### 5. Helm — Kubernetes package manager (installs ArgoCD, Vault, etc.)

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version
```

### 6. eksctl — CLI tool for creating and managing EKS clusters

```bash
ARCH=amd64
PLATFORM=$(uname -s)_$ARCH
curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"
tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version
```

### 7. GitHub CLI — manage GitHub repos and PRs from terminal

```bash
sudo apt install gh -y
gh --version
```

### 8. Trivy — scans container images for known CVEs

```bash
sudo apt-get install -y wget apt-transport-https gnupg

wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | \
  gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] \
  https://aquasecurity.github.io/trivy-repo/deb generic main" | \
  sudo tee /etc/apt/sources.list.d/trivy.list

sudo apt-get update && sudo apt-get install trivy -y
trivy --version
```

### 9. Cosign — cryptographically signs Docker images for supply chain security

```bash
curl -O -L "https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64"
sudo mv cosign-linux-amd64 /usr/local/bin/cosign
sudo chmod +x /usr/local/bin/cosign
cosign version
```

### 10. ArgoCD CLI — manages ArgoCD deployments from terminal

```bash
curl -sSL -o argocd-linux-amd64 \
  https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
argocd version --client
```

### ✅ Verify All Tools

Run this single command to confirm everything is installed correctly:

```bash
echo "=== Tool Verification ===" && \
aws --version && \
terraform --version | head -1 && \
kubectl version --client 2>/dev/null | head -1 && \
docker --version && \
helm version --short && \
eksctl version && \
trivy --version | head -1 && \
cosign version 2>/dev/null | head -1 && \
argocd version --client 2>/dev/null | head -1 && \
echo "" && echo "✅ All tools installed successfully!"
```

---

## ⚙️ Step 2: Configure AWS CLI

```bash
aws configure
```

You will be prompted for 4 values:

```
AWS Access Key ID:      → Your Access Key from IAM
AWS Secret Access Key:  → Your Secret Key from IAM
Default region name:    → ap-south-1   (Mumbai)
Default output format:  → json
```

> ��� **How to get your Access Key:** AWS Console → IAM → Users → Your User → Security Credentials → Create Access Key

Verify your configuration works:

```bash
aws sts get-caller-identity
# Expected output: your AWS Account ID, UserID, and ARN
```

---

## ��� Step 3: Setup GitHub Repository

```bash
# Authenticate with GitHub
gh auth login
# Select: GitHub.com → HTTPS → Login with web browser

# Create the repository and clone it
gh repo create devsecops-platform --public --clone
cd devsecops-platform

# Create the full project folder structure
mkdir -p terraform/modules/{eks,vpc,iam} \
         terraform/environments/{dev,prod} \
         argocd/{apps,projects} \
         k8s/{base,overlays/{dev,prod}} \
         policies/{kyverno,conftest} \
         .github/workflows \
         app

# Initial commit
git add .
git commit -m "feat: initial project structure"
git push origin main

echo "✅ Repository structure created!"
```

---

## ���️ Project Phases

| Phase | Topic | Duration |
|-------|-------|----------|
| Phase 1 | Terraform EKS with security hardening (KMS, IMDSv2, private endpoint) | Week 1–2 |
| Phase 2 | ArgoCD GitOps — App of Apps pattern, zero manual kubectl | Week 2–3 |
| Phase 3 | DevSecOps CI — Trivy, Snyk, OPA Conftest, Cosign image signing | Week 3–4 |
| Phase 4 | HashiCorp Vault — IRSA auth, dynamic database credentials | Week 4–5 |
| Phase 5 | Kyverno — admission controller blocking insecure workloads | Week 5–6 |
| Phase 6 | Falco runtime security + Grafana security dashboards | Week 6–7 |
| Phase 7 | Documentation, portfolio, interview prep | Week 7–8 |

---

## ���️ Security Layers

This project implements **Defense in Depth** — 6 independent layers of security:

```
Layer 1: Snyk / Trivy in CI        → Block vulnerable dependencies & images
Layer 2: Cosign Image Signing      → Prove image came from your CI pipeline
Layer 3: OPA Conftest in CI        → Validate K8s manifests before deploy
Layer 4: Kyverno in Cluster        → Block insecure workloads at API server
Layer 5: HashiCorp Vault           → Eliminate credential theft risk
Layer 6: Falco Runtime Security    → Detect attacks on running containers
```

---

## ��� Folder Structure

```
devsecops-platform/
├── terraform/
│   ├── modules/
│   │   ├── eks/           # EKS cluster + node groups
│   │   ├── vpc/           # VPC, subnets, NAT gateway, IGW
│   │   └── iam/           # IRSA roles and policies
│   └── environments/
│       ├── dev/
│       └── prod/
├── argocd/
│   ├── apps/              # ArgoCD Application manifests
│   └── projects/          # ArgoCD Project definitions
├── k8s/
│   ├── base/              # Kustomize base configs
│   └── overlays/          # dev / prod environment overlays
├── policies/
│   ├── kyverno/           # In-cluster admission policies
│   └── conftest/          # OPA policies for CI pipeline
├── .github/
│   └── workflows/         # GitHub Actions CI pipelines
└── app/                   # Sample microservice application
```

---

## ��� Author

**Saumya Singh** — DevOps Engineer  
AWS Certified Cloud Practitioner | AWS Certified Developer – Associate  
[LinkedIn](https://linkedin.com/in/your-profile) · [GitHub](https://github.com/your-username)

---

> ⭐ If this project helped you, consider giving it a star!
