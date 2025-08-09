# Terraform for GCP

- Environment variable `TF_VAR_gcp_project_id` for GCP project ID
- Google service account JSON file `./google-credentials.json` for GCP credentials
- SSH key `./ssh_key` for SSH access to the server

## Generate SSH key

Make sure to make proper username for public key.

```bash
ssh-keygen -t ed25519 -f ssh_key -C "vpn" -N ""
```
