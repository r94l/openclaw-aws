# OpenClaw on Azure — Terraform + Hardened VM

Deploy a hardened, 24/7 OpenClaw AI agent on Azure using Terraform and cloud-init.
Zero manual server steps. Port 22 is never opened.

## Architecture

```
Your Machine (Tailscale) ──► Azure VM (Tailscale)
                                 └── Docker: OpenClaw (port 18789, localhost only)
                                 └── UFW: only port 2222 open publicly
                                 └── fail2ban + unattended-upgrades
```

After confirming Tailscale works, port 2222 is removed from the NSG and the VM
has **zero public ports** — all access flows through the encrypted Tailscale network.

---

## Prerequisites

- [Terraform >= 1.5](https://developer.hashicorp.com/terraform/install)
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) — logged in (`az login`)
- [Tailscale account](https://tailscale.com) — with an auth key ready
- Your public IP: `curl ifconfig.me`

---

## Quick Start

### 1. Clone and configure

```bash
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

Fill in:
- `allowed_ssh_cidr` — your IP (from `curl ifconfig.me`) + `/32`
- `tailscale_authkey` — from https://login.tailscale.com/admin/settings/keys

Or pass the Tailscale key as an env var (more secure):
```bash
export TF_VAR_tailscale_authkey="tskey-auth-xxxx"
```

### 2. Deploy

```bash
terraform init
terraform plan     # review what will be created
terraform apply
```

Terraform will output your public IP and a ready-to-run SSH command.

### 3. Wait for cloud-init (~3–5 minutes)

After `terraform apply` completes, the VM is booting and running cloud-init.
This installs Docker, Tailscale, and OpenClaw. Don't SSH in yet — wait ~5 minutes.

To check progress once you're in:
```bash
sudo tail -f /var/log/cloud-init-output.log
```

### 4. SSH in and configure OpenClaw

```bash
# The SSH command is shown in terraform output
ssh -p 2222 -i ./openclaw.pem openclaw@<PUBLIC_IP>

# Once inside:
cd ~/openclaw
cp .env.template .env
nano .env          # add your ANTHROPIC_API_KEY and GATEWAY_TOKEN
docker compose up -d
docker compose logs -f   # watch startup
```

### 5. Access OpenClaw via Tailscale

```bash
# On the VM, get the Tailscale IP
sudo tailscale ip -4
```

On your local machine (also connected to Tailscale):
```
http://<tailscale-ip>:18789
```

Use the GATEWAY_TOKEN you set in .env to log in.

### 6. Lock down (remove public SSH port)

Once OpenClaw is running and accessible via Tailscale:

In `main.tf`, delete or comment out the `ssh_inbound` security rule block, then:

```bash
terraform apply
```

Port 2222 is now closed. The VM has zero public ports.
SSH going forward: `tailscale ssh openclaw@openclaw-azure`

---

## Day 2 Operations

### Updating OpenClaw

```bash
cd ~/openclaw
docker compose pull
docker compose up -d
```

### Viewing logs

```bash
docker compose logs -f openclaw
```

### Checking memory backups

```bash
ls -lh /var/backups/openclaw/
```

### Resizing the VM

In `terraform.tfvars`, change `vm_size` to a larger SKU, then:
```bash
terraform apply
```
The VM will be deallocated and resized. OpenClaw will restart automatically
(Docker restart policy is `unless-stopped`).

### Destroying everything

```bash
terraform destroy
```

All Azure resources are deleted. Your `.pem` key and `terraform.tfstate` remain locally.

---

## Security Hardening Summary

| Layer | What's done |
|---|---|
| SSH | Non-standard port (2222), key-only auth, root login disabled, fail2ban |
| Firewall | UFW default deny inbound, only 2222 open (removed after Tailscale confirmed) |
| OS | Unattended security updates, no password auth |
| Docker | Port 18789 bound to localhost only — never publicly exposed |
| Network | Azure NSG denies all inbound except 2222 |
| Access | All post-setup access via Tailscale encrypted tunnel |

---

## Cost Estimate (Azure)

| Resource | ~Monthly Cost |
|---|---|
| Standard_B2s VM | ~$30 |
| Standard SSD (30 GB) | ~$3 |
| Public IP (Static) | ~$4 |
| Bandwidth (egress) | ~$1–5 |
| **Total** | **~$38–42/mo** |

Upgrade to `Standard_D2s_v3` (~$70/mo) for better CPU/memory performance.

---

## File Structure

```
openclaw-azure/
├── main.tf                    # Core infrastructure
├── variables.tf               # All input variables with descriptions
├── outputs.tf                 # SSH command, IP, next steps
├── terraform.tfvars.example   # Template — copy to terraform.tfvars
├── .gitignore                 # Keeps secrets out of git
└── scripts/
    └── cloud-init.yaml        # Full VM setup script (runs at first boot)
```
