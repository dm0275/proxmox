# Resource definition to create a Proxmox instance
resource "proxmox_vm_qemu" "instance" {
    # Basic configuration
    name        = var.instance_name          # Name of the new instance
    target_node = var.proxmox_node           # Proxmox node to deploy the instance on
    vmid        = var.instance_vm_id         # Unique VM ID for the instance
    clone       = var.template_name          # Name of the Proxmox template to clone

    # Disk configuration
    disk {
        slot    = "virtio0"                  # Specify the disk slot (virtio for better performance)
        size    = var.disk_size              # Size of the disk for the instance (e.g., "50G")
        type    = "disk"                     # Disk type
        storage = "local-lvm"                # Proxmox storage pool for the disk
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
    network {
        id     = 0                           # Network interface ID
        bridge = "vmbr0"                     # Network bridge to connect the instance to
        model  = "virtio"                    # Network adapter model for better performance
    }
}

# Output the instance details
output "instance_details" {
    description = "Details of the created Proxmox instance" # Description of the output
    value = {
        name        = proxmox_vm_qemu.instance.name        # Name of the Proxmox instance
        vmid        = proxmox_vm_qemu.instance.vmid        # VM ID of the created instance
        vmip        = proxmox_vm_qemu.instance.ssh_host   # IP config for the VM
        target_node = proxmox_vm_qemu.instance.target_node # Proxmox node where the instance is deployed
    }
}