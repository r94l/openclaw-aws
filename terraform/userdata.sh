#!/bin/bash

set -e

# Log all output for debugging
exec > /var/log/userdata.log 2>&1

echo "Starting userdata script..."

# Update system 
sudo apt update && sudo apt upgrade -y 
# Create a new user (replace 'openclaw' if you want a different name) 
sudo adduser --disabled-password openclaw

# (Enter a strong password when prompted) 
# Grant sudo rights 

sudo usermod -aG sudo openclaw
# 1. Create the SSH directory for the new user 
sudo mkdir -p /home/openclaw/.ssh 
# 2. Copy the authorized keys from 'ubuntu' to 'openclaw' 
sudo cp /home/ubuntu/.ssh/authorized_keys /home/openclaw/.ssh/ 
# 3. Fix permissions (CRITICAL: If this is wrong, login will fail) 
sudo chown -R openclaw:openclaw /home/openclaw/.ssh 
sudo chmod 700 /home/openclaw/.ssh 
sudo chmod 600 /home/openclaw/.ssh/authorized_keys

# Set default policies 
sudo ufw default deny incoming 
sudo ufw default allow outgoing 
# Allow the FUTURE port 
sudo ufw allow 2222/tcp 
# Enable the firewall 
sudo ufw --force enable

# Disable password authentication (key-only login)
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config

# Change SSH port to 2222
sed -i 's/^#\?Port.*/Port 2222/' /etc/ssh/sshd_config

# Disable root login
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config

# Stop the socket listener
sudo systemctl stop ssh.socket 
sudo systemctl disable ssh.socket 
# Restart the SSH service to apply your new config 
sudo systemctl restart ssh

# Install Docker dependencies 
sudo apt install apt-transport-https ca-certificates 
curl software-properties-common -y 
# Add Docker GPG key & Repository 
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg echo "deb [arch= $(dpkg --print-architecture ) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs ) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null 
# Install Docker 
sudo apt update 
sudo apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y 
# Allow 'openclaw' user to run Docker without sudo 
sudo usermod -aG docker ${ USER }

newgrp docker

echo "Userdata script completed successfully"
