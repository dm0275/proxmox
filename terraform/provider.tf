# Specify the provider
terraform {
    required_providers {
        proxmox = {
            source  = "Telmate/proxmox"
            version = "3.0.1-rc6"
        }
    }
}

# Define variables
variable "proxmox_api_url" {
    description = "URL of the Proxmox API endpoint"
    type        = string
}

variable "proxmox_api_token_id" {
    description = "Proxmox API Token ID"
    type        = string
}

variable "proxmox_api_token_secret" {
    description = "Proxmox API Token Secret"
    type        = string
    sensitive   = true
}

variable "proxmox_node" {
    description = "Proxmox node to deploy the instance"
    type        = string
    default     = "proxmox"
}

variable "template_name" {
    description = "Name of the Proxmox template to clone"
    type        = string
    default     = "ubuntu-24.04-template"
}

variable "instance_name" {
    description = "Name of the new Proxmox instance"
    type        = string
    default     = "ubuntu-instance-01"
}

variable "instance_vm_id" {
    description = "VM ID for the new instance"
    type        = number
    default     = 200
}

variable "disk_size" {
    description = "Disk size for the new instance"
    type        = string
    default     = "120G"
}

variable "cpu_cores" {
    description = "Number of CPU cores for the instance"
    type        = number
    default     = 2
}

variable "memory_size" {
    description = "Memory size for the instance in MB"
    type        = number
    default     = 2048
}

provider "proxmox" {
    pm_api_url      = var.proxmox_api_url      # Proxmox API URL
    pm_api_token_id = var.proxmox_api_token_id # Proxmox API Token ID
    pm_api_token_secret = var.proxmox_api_token_secret # Proxmox API Token Secret
    pm_tls_insecure = true                     # Skip TLS verification (Optional)
}
