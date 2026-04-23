# 🦞 OpenClaw AI Agent on Azure — Terraform + Docker + Tailscale

> Deploy a secure, 24/7 always-on AI agent on an Azure VM using Terraform for infrastructure provisioning, Docker for containerisation, and Tailscale for zero-trust private networking.

Inspired by: [Deploy Your Own 24/7 AI Agent on AWS EC2 with Docker & Tailscale — The Secure Way](https://blog.thecloudopscommunity.org/deploy-your-own-24-7-ai-agent-on-aws-ec2-with-docker-tailscale-the-secure-way-e8e3dadde6a4) — adapted here for **Microsoft Azure** with **Terraform** as the IaC layer.

---

## 📐 Architecture Overview

```
┌────────────────────────────────────────────────────┐
│                  Your Machine                       │
│  terraform apply ──► Azure VM (Ubuntu 22.04 LTS)   │
│  ssh azureuser@<PUBLIC_IP>                          │
└──────────────────────┬─────────────────────────────┘
                       │ SSH (port 22 via NSG)
                       ▼
┌────────────────────────────────────────────────────┐
│               Azure VM                              │
│  ┌──────────────────────────────────────────────┐  │
│  │  Docker Container — OpenClaw Gateway         │  │
│  │  Port 18789 (web UI, Tailscale-only)         │  │
│  └──────────────────────────────────────────────┘  │
│  Tailscale (private mesh network)                  │
└────────────────────────────────────────────────────┘
                       │ Tailscale VPN
                       ▼
            Your devices (phone, laptop, etc.)
```

No public ports exposed beyond SSH. OpenClaw's web UI is accessed exclusively over Tailscale.

---

## ✅ What You'll Have by the End

- A hardened Ubuntu 22.04 server provisioned on Azure via Terraform
- Docker running OpenClaw in an isolated, persistent container
- Secure private access via Tailscale — no inbound ports exposed to the internet
- A fully functional AI assistant reachable from your browser or phone

---

## 🧰 Prerequisites

Before you begin, make sure you have the following:

| Tool | Notes |
|---|---|
| [Terraform](https://developer.hashicorp.com/terraform/install) ≥ 1.5 | Infrastructure provisioning |
| [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) | Authenticate with your Azure account |
| SSH key pair | Used for VM access (`~/.ssh/openclaw-azure`) |
| [Tailscale account](https://tailscale.com/) | Free tier is sufficient |
| Anthropic API key | Recommended — Claude Sonnet/Opus gives best agent performance |
| OpenAI API key | Optional, can be used as a backup model provider |

---

## ⚙️ What Terraform Provisions

The `terraform/` directory defines the full Azure infrastructure:

- **Resource Group** — logical container for all resources
- **Virtual Network (VNet)** + **Subnet** — isolated network layer
- **Public IP** — static IP for SSH access
- **Network Security Group (NSG)** — restricts inbound traffic to SSH only
- **Linux VM** — Ubuntu 22.04 LTS (Standard_B1ms or similar)
- **SSH key authentication** — password auth disabled

---

## 🚀 Step 1 — Provision the VM with Terraform

```bash
# Authenticate with Azure
az login

# Navigate to the Terraform directory
cd terraform

# Initialise Terraform
terraform init

# Preview the changes
terraform plan

# Apply and provision the infrastructure
terraform apply
```

Once complete, note the **public IP** output — you'll need it to SSH in.

---

## 🔐 Step 2 — SSH into the VM

```bash
ssh -i ~/.ssh/openclaw-azure azureuser@<PUBLIC_IP>
```

> Replace `<PUBLIC_IP>` with the value from `terraform output` or the Azure portal.

---

## 🐳 Step 3 — Install Docker

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker

# Add your user to the docker group (avoids needing sudo for every docker command)
sudo usermod -aG docker $USER

# Apply the group change without logging out
newgrp docker
```

Verify Docker is running:

```bash
docker --version
docker run hello-world
```

---

## 🔗 Step 4 — Install and Connect Tailscale

Tailscale creates a secure private mesh network between your VM and your devices — so OpenClaw's web UI is never publicly exposed.

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

Follow the authentication URL printed in the terminal to approve the device in your Tailscale dashboard. Once connected, note your VM's **Tailscale IP** (e.g. `100.x.x.x`) — this is how you'll access the OpenClaw web UI later.

---

## 🦞 Step 5 — Set Up OpenClaw with Docker Compose

Clone the official OpenClaw repository:

```bash
git clone https://github.com/openclaw/openclaw.git
cd openclaw
```

Run the official setup script, which uses Docker Compose and walks you through initial configuration:

```bash
bash docker-setup.sh
```

The script creates two persistent directories on the host:

| Path | Purpose |
|---|---|
| `~/.openclaw` | Configuration, memory, API keys, agent settings |
| `~/openclaw/workspace` | Working directory — files the agent creates appear here |

### First-Run Configuration

During the interactive setup wizard, you'll configure:

- **Model provider** — choose Anthropic (recommended for Claude Sonnet/Opus) or OpenAI
- **API keys** — stored in a `.env` file, never committed to Git
- **Messaging channel** — Telegram is the easiest to configure (create a bot via `@BotFather` and provide the token)
- **Gateway settings** — default port is `18789`

> ⚠️ Never commit your `.env` file to Git. It contains your API keys and tokens.

### Create a `.env` File

```bash
cat > .env <<EOF
ANTHROPIC_API_KEY=your-anthropic-api-key
OPENAI_API_KEY=your-openai-api-key   # optional
EOF
```

---

## 🚀 Step 6 — Start the Agent

```bash
# Run onboarding (first time only)
docker compose run --rm openclaw-cli onboard

# Start the gateway in the background
docker compose up -d openclaw-gateway
```

Verify the container is running and healthy:

```bash
docker ps
docker logs -f openclaw-openclaw-gateway-1
```

---

## 🌐 Step 7 — Access the Web UI via Tailscale

Because no public port is exposed for the web UI, access it through your Tailscale IP:

```
http://<TAILSCALE_IP>:18789
```

The dashboard requires a session token. Retrieve it with:

```bash
docker compose run --rm openclaw-cli dashboard --no-open
```

Copy the full URL including the `?token=...` parameter and open it in your browser.

---

## 📱 Step 8 — Pair Your Messaging Platform (Telegram)

If you chose Telegram during setup, OpenClaw will send your bot a pairing code. Approve it with:

```bash
docker compose run --rm openclaw-cli pairing approve telegram <CODE>
```

You can now send instructions to your AI agent directly from your phone via Telegram — 24/7.

---

## 🔧 Useful Docker Commands

```bash
# View live logs
docker compose logs -f openclaw-gateway

# Stop the agent
docker compose stop

# Restart after config changes
docker compose restart

# Update to the latest OpenClaw version
docker compose pull && docker compose up -d

# Open a shell inside the container
docker compose exec openclaw-gateway bash

# Run CLI commands
docker compose run --rm openclaw-cli <command>
```

---

## 🧹 Tear Down the Infrastructure

When you're done, destroy all Azure resources cleanly:

```bash
cd terraform
terraform destroy
```

Your configuration data in `~/.openclaw` on the VM will be lost when the VM is deleted. Back up anything important beforehand.

---

## 🔒 Security Notes

- **No public web ports** — OpenClaw's UI (port `18789`) is only reachable over Tailscale
- **SSH only** — the NSG restricts all inbound traffic except SSH (port 22)
- **SSH key auth only** — password authentication is disabled on the VM
- **Docker isolation** — the agent runs inside a container, limiting its blast radius on the host
- **`.env` file** — keep API keys out of version control; add `.env` to your `.gitignore`

---

## 💡 Why This Project

| Aspect | Approach |
|---|---|
| Infrastructure | Terraform (IaC) — fully reproducible and destroyable |
| Cloud | Microsoft Azure (instead of AWS) |
| Runtime | Docker — isolated, portable, easy to update |
| Networking | Tailscale — zero-trust, no open inbound ports |
| AI Backend | Anthropic Claude (or OpenAI as fallback) |

---

## 🔮 Potential Improvements

- **`cloud-init` / `user_data`** — automate Docker + Tailscale installation at VM boot time via Terraform
- **Private VM** — remove the public IP entirely; access exclusively over Tailscale
- **Azure Key Vault** — store API keys as secrets instead of a `.env` file
- **CI/CD pipeline** — automate `terraform apply` and container updates on push

---

## 📚 References

- [Original blog post — CloudOps Community](https://blog.thecloudopscommunity.org/deploy-your-own-24-7-ai-agent-on-aws-ec2-with-docker-tailscale-the-secure-way-e8e3dadde6a4)
- [OpenClaw Documentation](https://docs.openclaw.ai)
- [OpenClaw Docker Guide](https://docs.openclaw.ai/install/docker)
- [Tailscale Docs](https://tailscale.com/kb)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
