# 🤖 OpenClaw AI Agent on Azure (Terraform + Docker + Tailscale)

This project is a cloud-deployed AI agent setup inspired by:

👉 https://blog.thecloudopscommunity.org/deploy-your-own-24-7-ai-agent-on-aws-ec2-with-docker-tailscale-the-secure-way-e8e3dadde6a4

Instead of AWS EC2, this version uses:

- Microsoft Azure (VM provisioning)
- Terraform (Infrastructure as Code)
- Manual post-deploy setup (Docker + Tailscale + AI Agent stack)

The goal is to create a secure, 24/7 always-on AI agent environment that is fully reproducible and destroyable.

---

# 🏗️ Architecture Overview

Terraform → Azure Resource Group → VNet + Subnet → Linux VM (Ubuntu 22.04) → Public IP + SSH → Manual setup (Docker + Tailscale + AI Agent)

---

# ⚙️ What Terraform provisions

- Resource Group
- Virtual Network (VNet)
- Subnet
- Public IP
- Network Security Group (SSH)
- Linux VM (Ubuntu 22.04)
- SSH key authentication

---

# 🚀 Prerequisites

- Terraform ≥ 1.5
- Azure CLI
- SSH key pair

Login:
az login

---

# 🔑 SSH Key Setup

ssh-keygen -t rsa -b 4096 -f ~/.ssh/openclaw-azure

---

# 🧱 Deployment

cd terraform
terraform init
terraform plan
terraform apply

---

# 🔐 SSH into VM

ssh -i ~/.ssh/openclaw-azure azureuser@<PUBLIC_IP>

---

# 🐳 Manual Setup

## Docker
sudo apt update
sudo apt install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

## Tailscale
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

## Run agent
docker run -d --name ai-agent -p 3000:3000 your-image

---

# 🧹 Destroy

terraform destroy

---

# 💡 Why this project

- IaC with Terraform
- Azure-native deployment
- Secure remote compute
- 24/7 AI agent hosting

---

# 🔮 Improvements

- cloud-init automation
- private VM + Tailscale-only access
- CI/CD pipeline
