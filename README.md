# Sing-Box Deployment for ckt1031

This is my Sing-Box script that automate the deployment of Sing-Box on cloud platform.

Useful for me when going to Mainland China, since major VPN services like Surfshark, NordVPN, etc. are blocked in China, they use OpenVPN, IPSec, IKEv2 and WireGuard, which are obvious under their request characteristics and request statistics from China's GFW.

The proxy protocol is **XTLS REALITY** from Xray project, which has it's own stealthiness and can bypass GFW's detection.

- **Terraform** for cloud platform deployment
- **Sing-Box** for proxy server
- **Bun** for script

## Usage

```bash
bun install
bun generate.ts
```

After the server is created, you have to replace the `SERVER_IP_HERE` in the `config/client.json` with the server's IP before adding to Sing-Box client.

## Terraform

```bash
cd terraform/gcp # or terraform/azure for Azure
terraform init
terraform apply
# Show the server's IP
terraform output public_ip
# Refresh data
terraform refresh
```
