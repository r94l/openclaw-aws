output "vm_public_ip" {
  description = "Public IP of the OpenClaw VM — use this for initial SSH access"
  value       = azurerm_public_ip.openclaw.ip_address
}

output "ssh_command" {
  description = "Ready-to-run SSH command using the generated key"
  value       = "ssh -p ${var.ssh_port} -i ./openclaw.pem ${var.admin_username}@${azurerm_public_ip.openclaw.ip_address}"
}

output "private_key_path" {
  description = "Path to the generated SSH private key"
  value       = local_sensitive_file.private_key.filename
}

output "tailscale_next_steps" {
  description = "What to do after provisioning is complete"
  value       = <<-EOT

    ── NEXT STEPS ──────────────────────────────────────────────────────────
    1. Wait 3–5 minutes for cloud-init to finish (Docker + OpenClaw install)

    2. SSH in to verify:
       ${local_sensitive_file.private_key.filename} must exist with chmod 600
       ssh -p ${var.ssh_port} -i ./openclaw.pem ${var.admin_username}@${azurerm_public_ip.openclaw.ip_address}

    3. Check cloud-init logs if anything seems off:
       sudo tail -f /var/log/cloud-init-output.log

    4. Confirm Tailscale is connected:
       sudo tailscale status

    5. Access OpenClaw via Tailscale IP (NOT the public IP):
       http://<tailscale-ip>:18789

    6. Once Tailscale is confirmed working, LOCK DOWN SSH:
       In terraform.tfvars, comment out or remove the ssh_inbound NSG rule,
       then run: terraform apply
       After this, port 2222 is closed. Use Tailscale SSH only.
    ────────────────────────────────────────────────────────────────────────
  EOT
}
