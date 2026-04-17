# Deploy Your Own 24/7 AI Agent on AWS EC2 with Docker & Tailscale (The Secure Way)
Step-by-step process to securely set up an AI agent running as a Docker container.

In this guide, we’ll deploy OpenClaw (also known as Moltbot/Clawdbot) on an AWS EC2 instance using Docker containers. But we’re not just going to spin up a container and call it a day. We’ll harden our server, lock down SSH access, and use Tailscale to create a secure private network that only you can access.

# What You’ll Have by the End
- A hardened Ubuntu server with non-standard SSH configuration
- Docker running OpenClaw in an isolated container
- Secure private access via Tailscale (no public ports exposed)
- A fully functional AI assistant accessible from your browser Let’s get started.

Prerequisites
Before we dive in, make sure you have the following ready:

Cloud Infrastructure
AWS Account with EC2 access
A fresh Ubuntu 24.04 LTS instance (Recommended specs: 2 vCPU, 4GB RAM, 15GB storage)
Key Pair: Your .pem file from AWS (e.g., moltbot.pem) saved on your local computer
Current Access: Ability to SSH into the instance as the default ubuntu user
