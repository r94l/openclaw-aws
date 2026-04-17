# openclaw-aws

Deploy OpenClaw (Moltbot/Clawdbot) as a 24/7 AI agent on AWS EC2 using Docker and Tailscale — hardened, containerized, and privately accessible with zero public ports exposed.

Based on this guide: [Deploy Your Own 24/7 AI Agent on AWS EC2 with Docker & Tailscale](https://medium.com/thecloudopscommunity/deploy-your-own-24-7-ai-agent-on-aws-ec2-with-docker-tailscale-the-secure-way-e8e3dadde6a4)

## What You Get

- Ubuntu 24.04 EC2 instance provisioned via Terraform
- Hardened SSH on port 2222 (non-default)
- OpenClaw running in an isolated Docker container
- Secure private access via Tailscale — no inbound ports exposed beyond SSH
- IAM role with ECR read and Secrets Manager access attached to the instance
- Encrypted EBS root volume (gp3, 20GB)

## Prerequisites

- AWS account with credentials configured (`aws configure`)
- Terraform >= 1.0 installed ([install guide](https://developer.hashicorp.com/terraform/install))
- An existing VPC and subnet in your target region
- An EC2 key pair created in AWS
- A [Tailscale](https://tailscale.com) account + auth key

## Project Structure

```
.
├── terraform/
│   ├── main.tf          # EC2 instance, security group, IAM role & profile
│   ├── variables.tf     # Input variable declarations
│   ├── outputs.tf       # Output values (e.g. instance IP)
│   ├── terraform.tfvars # Your variable values (gitignored)
│   └── userdata.sh      # Bootstrap script — runs automatically on first boot
└── README.md
```

## Variables

Create a `terraform.tfvars` file inside the `terraform/` directory:

```hcl
project_name  = "openclaw"
environment   = "dev"
aws_region    = "us-east-1"
ami_id        = "ami-xxxxxxxxxxxxxxxxx"  # Ubuntu 24.04 LTS
instance_type = "t3.medium"
key_pair_name = "your-key-pair-name"
vpc_id        = "vpc-xxxxxxxxxxxxxxxxx"
subnet_id     = "subnet-xxxxxxxxxxxxxxxxx"
```

## Deployment

```bash
git clone https://github.com/r94l/openclaw-aws.git
cd openclaw-aws/terraform

cp terraform.tfvars.example terraform.tfvars
# fill in your values

terraform init
terraform plan
terraform apply
```

On first boot, `userdata.sh` runs automatically as EC2 User Data and handles the full Phase 1 setup — package updates, Docker installation, SSH hardening, and Tailscale onboarding.

Once the instance is up, connect via Tailscale and follow Phase 2 of the guide to deploy the OpenClaw container.

## Security Notes

- SSH is exposed on port **2222** only — restrict the `cidr_blocks` in `main.tf` to your IP in production
- All access beyond SSH is routed through Tailscale's encrypted private network
- Root EBS volume is encrypted at rest
- IAM role is scoped to ECR read-only and Secrets Manager

## Teardown

```bash
terraform destroy
```
