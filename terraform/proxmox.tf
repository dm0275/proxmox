# Resource definition to create a Proxmox instance
resource "proxmox_vm_qemu" "instance" {
    # Basic configuration
    name        = var.instance_name
    target_node = var.proxmox_node
    vmid        = var.instance_vm_id
    clone       = var.template_name

    # Cloud-init user account config
    ciuser      = var.vm_username
    cipassword  = var.vm_password
    sshkeys     = var.public_ssh_key

    # Disk configuration for cloud-init
    disk {
        slot    = "ide0"
        type    = "cloudinit"
        storage = "local-lvm"
    }

    # Main disk configuration
    disk {
        # Specify the disk slot (virtio for better performance)
        slot    = "virtio0"
        size    = var.disk_size
        type    = "disk"
        storage = "local-lvm"
    }

    # CPU configuration
    cores = var.cpu_cores

    # Memory configuration
    memory = var.memory_size

    # Operating system type
    os_type = "cloud-init"

    # Enable QEMU guest agent
    agent = 1

    # Boot settings, true ensures the instance starts automatically when Proxmox boots
    onboot = true

    # Network configuration
    ipconfig0 = "ip=dhcp"
    network {
        id     = 0
        bridge = "vmbr0"
        model  = "virtio"
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
    description = "Details of the created Proxmox instance"
    value = {
        name        = proxmox_vm_qemu.instance.name
        vmid        = proxmox_vm_qemu.instance.vmid
        vmip        = proxmox_vm_qemu.instance.ssh_host
        target_node = proxmox_vm_qemu.instance.target_node
    }
}
