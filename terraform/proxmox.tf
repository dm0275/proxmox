# Resource definition to create a Proxmox instance
resource "proxmox_vm_qemu" "instance" {
    # Basic configuration
    name        = var.instance_name          # Name of the new instance
    target_node = var.proxmox_node           # Proxmox node to deploy the instance on
    vmid        = var.instance_vm_id         # Unique VM ID for the instance
    clone       = var.template_name          # Name of the Proxmox template to clone
    ciuser      = var.vm_username            # Cloud-init user account for the VM
    cipassword  = var.vm_password            # Cloud-init user password for the VM
    sshkeys     = var.public_ssh_key         # SSH public key for secure access to the VM

    # Disk configuration for cloud-init
    disk {
        slot    = "ide0"                     # Disk slot for cloud-init ISO configuration
        type    = "cloudinit"                # Disk type for cloud-init data
        storage = "local-lvm"                # Proxmox storage pool for cloud-init disk
    }

    # Main disk configuration
    disk {
        slot    = "virtio0"                  # Specify the disk slot (virtio for better performance)
        size    = var.disk_size              # Size of the disk for the instance (e.g., "50G")
        type    = "disk"                     # Disk type for VM storage
        storage = "local-lvm"                # Proxmox storage pool for the main disk
    }

    # CPU configuration
    cores = var.cpu_cores                    # Number of CPU cores allocated to the instance

    # Memory configuration
    memory = var.memory_size                 # Amount of memory (RAM) in MB allocated to the instance

    # Operating system type
    os_type = "cloud-init"                   # Specify that the instance will use cloud-init for initialization

    # Enable QEMU guest agent
    agent = 1                                # Enable QEMU Guest Agent for improved management and monitoring

    # Boot settings
    onboot = true                            # Ensure the instance starts automatically when Proxmox boots

    # Network configuration
    ipconfig0 = "ip=dhcp"                    # Configure network interface to use DHCP for IP assignment
    network {
        id     = 0                           # Network interface ID
        bridge = "vmbr0"                     # Network bridge to connect the instance to
        model  = "virtio"                    # Network adapter model for better performance
    }
}

# Resource to configure the Proxmox VM after creation
resource "terraform_data" "configure-vm" {
    # Trigger reconfiguration when the VM ID changes
    triggers_replace = [
        proxmox_vm_qemu.instance.id
    ]

    # SSH connection settings
    connection {
        type     = "ssh"
        user     = var.vm_username
        password = var.vm_password
        host     = proxmox_vm_qemu.instance.ssh_host
    }

    # Provisioner to execute remote commands
    provisioner "remote-exec" {
        inline = [
            "sudo apt update"
        ]
    }
}

# Output the instance details
output "instance_details" {
    description = "Details of the created Proxmox instance" # Description of the output
    value = {
        name        = proxmox_vm_qemu.instance.name        # Name of the Proxmox instance
        vmid        = proxmox_vm_qemu.instance.vmid        # VM ID of the created instance
        vmip        = proxmox_vm_qemu.instance.ssh_host    # IP address of the VM for SSH access
        target_node = proxmox_vm_qemu.instance.target_node # Proxmox node where the instance is deployed
    }
}
