# Proxmox VM Automation

Automates Ubuntu VM lifecycle on Proxmox using:

- **Packer** to build a reusable Ubuntu 24.04 cloud-init template
- **Terraform** to clone and provision instances from that template
- **Make** targets for common workflows

## Repository Layout

- `packer/` builds the Proxmox template (`ubuntu-24.04-template` by default)
- `terraform/` clones template into a VM and runs post-creation provisioning scripts
- `Makefile` wraps common Packer/Terraform commands

## Prerequisites

Install on your workstation:

- [Packer](https://developer.hashicorp.com/packer)
- [Terraform](https://developer.hashicorp.com/terraform)
- `make`
- Access to a Proxmox API token with VM/template permissions

Also ensure:

- Ubuntu 24.04 installer ISO exists in Proxmox storage as `local:iso/ubuntu-24.04.1-live-server-amd64.iso` (or update `packer/ubuntu.pkr.hcl`)
- `packer/ssh/id_rsa` exists and matches the expected SSH key for the template build process

## Credentials and Variables

Two local files are expected and are gitignored:

- `packer/credentials.pkr.hcl`
- `terraform/credentials.auto.tfvars`

### `packer/credentials.pkr.hcl`

```hcl
proxmox_api_url          = "https://<proxmox-host>:8006/api2/json"
proxmox_api_token_id     = "<user@realm!tokenid>"
proxmox_api_token_secret = "<token-secret>"
proxmox_node             = "proxmox"
```

### `terraform/credentials.auto.tfvars`

```hcl
proxmox_api_url          = "https://<proxmox-host>:8006/api2/json"
proxmox_api_token_id     = "<user@realm!tokenid>"
proxmox_api_token_secret = "<token-secret>"

vm_username   = "ubuntu"
vm_password   = "<vm-password>"
public_ssh_key = "ssh-ed25519 AAAA..."

# Optional overrides
# template_name = "ubuntu-24.04-template"
# proxmox_node  = "proxmox"
```

## Build Template with Packer

From repository root:

```bash
make packer-validate
make packer-build
```

What this does:

- Creates a VM template (default ID `900`, name `ubuntu-24.04-template`)
- Uses autoinstall cloud-init from `packer/http/user-data`
- Enables `qemu-guest-agent`
- Cleans cloud-init/SSH machine identity for safe cloning

## Provision VM with Terraform

From repository root:

```bash
make terraform-plan
make terraform-provision
```

Defaults in `Makefile`:

- `instance_id=203`
- `instance_name="ubuntu-instance-03"`

Override per run:

```bash
make terraform-plan instance_id=210 instance_name='"ubuntu-dev-01"'
make terraform-provision instance_id=210 instance_name='"ubuntu-dev-01"'
```

Destroy VM:

```bash
make terraform-destroy instance_id=210 instance_name='"ubuntu-dev-01"'
```

## Post-Provisioning Behavior

Terraform copies and executes scripts from `terraform/files/`:

- `common.sh`
  - Installs base packages (`git`, `make`, `zsh`, etc.)
  - Installs Oh My Zsh and sets theme
- `docker.sh`
  - Installs Docker CE + plugins
  - Adds VM user to `docker` group
- `netdrive.sh`
  - Utility script for mounting SMB shares (not auto-run by current Terraform config)

## Make Targets

```bash
make help
```

Available targets:

- `packer-validate`
- `packer-build`
- `terraform-plan`
- `terraform-provision`
- `terraform-destroy`
- `terraform-clear-state`

## Notes

- Provider version is pinned to `Telmate/proxmox 3.0.1-rc6` in `terraform/provider.tf`.
- `pm_tls_insecure = true` and `insecure_skip_tls_verify = true` are enabled; use trusted certs in production.
- This project uses password-based cloud-init login by default (`vm_password`), plus injected SSH public key.
