variable "azure_subscription_id" {
  description = "The Azure subscription ID to deploy resources into."
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key to use for the VM admin user."
  type        = string
  default     = "../gcp/ssh_key.pub"
}

variable "ssh_private_key_path" {
  description = "Path to the SSH private key to use for provisioners to connect to the VM."
  type        = string
  default     = "../gcp/ssh_key"
}