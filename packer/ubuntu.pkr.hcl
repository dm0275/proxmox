# Packer Configuration Block
packer {
    required_plugins {
        proxmox = {
            version = ">= 1.1.3" # Minimum plugin version required
            source  = "github.com/hashicorp/proxmox"
        }
    }
}

# Variable Definitions
variable "proxmox_api_url" {
    type = string # URL of the Proxmox API endpoint
}

variable "proxmox_api_token_id" {
    type = string # Proxmox API Token ID
}

variable "proxmox_api_token_secret" {
    type = string # Proxmox API Token Secret
    sensitive = true
}

variable "proxmox_node" {
    type = string # Proxmox node to deploy the VM on
    default = "proxmox"
}

variable "vm_id" {
    type = string # Unique VM ID in Proxmox
    default = "900"
}

variable "vm_name" {
    type = string # Name of the VM template to be created
    default = "ubuntu-24.04-template"
}

variable "template_description" {
    type = string # Description for the VM template
    default = "Ubuntu 24.04 Image"
}

variable "iso_file" {
    type = string # ISO file to use for OS installation
    default = "local:iso/ubuntu-24.04.1-live-server-amd64.iso"
}

variable "disk_size" {
    type = string # Disk size for the VM
    default = "120G"
}

# Resource Definition for the VM Template
source "proxmox-iso" "ubuntu-server" {
    # Proxmox Connection Settings
    proxmox_url = "${var.proxmox_api_url}"
    username = "${var.proxmox_api_token_id}"
    token = "${var.proxmox_api_token_secret}"
    # Skip TLS verification for self-signed certificates (Optional)
    insecure_skip_tls_verify = true

    # VM General Settings
    node = "${var.proxmox_node}"
    vm_id = "${var.vm_id}"
    vm_name = "${var.vm_name}"
    template_description = "${var.template_description}"

    # VM System Settings
    # Enable QEMU Guest Agent for better VM management
    qemu_agent = true

    # VM Hard Disk Settings
    scsi_controller = "virtio-scsi-pci"

    boot_iso {
        # Type of the boot device
        type = "scsi"
        # Unmount ISO after installation
        unmount = true
        iso_file = "${var.iso_file}"
    }

    disks {
        disk_size = "${var.disk_size}"
        format = "qcow2"
        storage_pool = "local"
        type = "virtio"
    }

    # VM CPU Settings
    cores = "8"

    # VM Memory Settings
    memory = "16384"

    # VM Network Settings
    network_adapters {
        # Network adapter model
        model = "virtio"
        # Bridge interface for networking
        bridge = "vmbr0"
        # Disable Proxmox firewall for this VM
        firewall = "false"
    }

    # VM Cloud-Init Settings
    # Enable cloud-init for VM initialization
    cloud_init = true
    # Storage pool for cloud-init data
    cloud_init_storage_pool = "local-lvm"

    # Packer Boot Commands for Automated Installation
    boot_command = [
        "<esc><wait>",
        "e<wait>",
        "<down><down><down><end>",
        "<bs><bs><bs><bs><wait>",
        "autoinstall cloud-config-url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/user-data ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
        "<f10><wait>"
    ]
    # Boot priority
    boot = "c"
    # Wait time before booting
    boot_wait = "5s"

    # Packer HTTP and SSH Configuration
    # Directory for HTTP server content
    http_directory = "http"
    # SSH username for provisioning
    ssh_username = "ubuntu"
    # Path to SSH private key
    ssh_private_key_file = "ssh/id_rsa"
    # Timeout for SSH connections
    ssh_timeout = "20m"
}

# Build Definition
# Specifies the process of creating the VM template
build {
    name = "ubuntu-server"
    sources = ["proxmox-iso.ubuntu-server"]

    # Provisioners for VM Customization and Cleanup
    provisioner "shell" {
        inline = [
            "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
            "sudo rm /etc/ssh/ssh_host_*",
            "sudo truncate -s 0 /etc/machine-id",
            "sudo apt -y autoremove --purge",
            "sudo apt -y clean",
            "sudo apt -y autoclean",
            "sudo cloud-init clean",
            "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
            "sudo rm -f /etc/netplan/00-installer-config.yaml",
            "sudo sync"
        ]
    }

    provisioner "file" {
        source = "files/99-pve.cfg"              # Local file to copy
        destination = "/tmp/99-pve.cfg"          # Destination path in VM
    }

    provisioner "shell" {
        inline = [ "sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg" ] # Apply cloud-init configuration
    }
}
