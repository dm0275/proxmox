PACKER_DIR := ./packer
TERRAFORM_DIR := ./terraform
ISO_DIR := ./iso

# Terraform Vars
instance_id=
instance_id_min=100
instance_name="ubuntu-instance-03"
timestamp=`date +%s`

# Ubuntu ISO Vars
ubuntu_version=26.04
ubuntu_iso_name=ubuntu-$(ubuntu_version)-live-server-amd64.iso
ubuntu_iso_url=https://releases.ubuntu.com/$(ubuntu_version)/$(ubuntu_iso_name)
ubuntu_template_name=ubuntu-$(ubuntu_version)-template
template_id_min=900
template_id_max=999
proxmox_instance=proxmox.lan
proxmox_user=root
proxmox_iso_dir=/var/lib/vz/template/iso

.PHONY: help

default: help

download-iso: ## Download Ubuntu server ISO to ./iso
	@mkdir -p $(ISO_DIR); \
	curl -fL $(ubuntu_iso_url) -o $(ISO_DIR)/$(ubuntu_iso_name); \
	echo "Downloaded $(ubuntu_iso_name) to $(ISO_DIR)/"

upload-iso: ## Upload ISO from ./iso to Proxmox ISO storage via scp
	@scp $(ISO_DIR)/$(ubuntu_iso_name) $(proxmox_user)@$(proxmox_instance):$(proxmox_iso_dir)/$(ubuntu_iso_name)

next-template-id: ## Print next free template ID in range
	@venv/bin/python scripts/proxmox.py next-template-id \
		--proxmox-user $(proxmox_user) \
		--proxmox-instance $(proxmox_instance) \
		--template-id-min $(template_id_min) \
		--template-id-max $(template_id_max)

next-instance-id: ## Print next free VM instance ID from minimum
	@venv/bin/python scripts/proxmox.py next-instance-id \
		--proxmox-user $(proxmox_user) \
		--proxmox-instance $(proxmox_instance) \
		--instance-id-min $(instance_id_min) \
		--template-id-min $(template_id_min) \
		--template-id-max $(template_id_max)

packer-build: ## Build Proxmox template
	@venv/bin/python scripts/packer.py build \
		--packer-dir $(PACKER_DIR) \
		--credentials-file credentials.pkr.hcl \
		--ubuntu-version $(ubuntu_version) \
		--template-name $(ubuntu_template_name) \
		--template-description "Ubuntu $(ubuntu_version) Image" \
		--iso-name $(ubuntu_iso_name) \
		--iso-storage local \
		--proxmox-user $(proxmox_user) \
		--proxmox-instance $(proxmox_instance) \
		--template-id-min $(template_id_min) \
		--template-id-max $(template_id_max) \
		$(if $(packer_vm_id),--vm-id $(packer_vm_id),) \
		--packer-extra-args "$(PACKER_ARGS)"

packer-validate: ## Validate Packer configuration
	@venv/bin/python scripts/packer.py validate \
		--packer-dir $(PACKER_DIR) \
		--credentials-file credentials.pkr.hcl \
		--ubuntu-version $(ubuntu_version) \
		--template-name $(ubuntu_template_name) \
		--template-description "Ubuntu $(ubuntu_version) Image" \
		--iso-name $(ubuntu_iso_name) \
		--iso-storage local \
		--proxmox-user $(proxmox_user) \
		--proxmox-instance $(proxmox_instance) \
		--template-id-min $(template_id_min) \
		--template-id-max $(template_id_max) \
		$(if $(packer_vm_id),--vm-id $(packer_vm_id),) \
		--packer-extra-args "$(PACKER_ARGS)"

terraform-plan: ## Generate a TF plan
	@venv/bin/python scripts/terraform.py plan \
		--terraform-dir $(TERRAFORM_DIR) \
		--ubuntu-version $(ubuntu_version) \
		--template-name $(ubuntu_template_name) \
		$(if $(instance_id),--instance-id $(instance_id),) \
		--instance-id-min $(instance_id_min) \
		--template-id-min $(template_id_min) \
		--template-id-max $(template_id_max) \
		--instance-name $(instance_name) \
		--script-revision $(timestamp) \
		--proxmox-user $(proxmox_user) \
		--proxmox-instance $(proxmox_instance) \
		--terraform-extra-args "$(TF_ARGS)"

terraform-provision: ## Provision Proxmox instance
	@venv/bin/python scripts/terraform.py provision \
		--terraform-dir $(TERRAFORM_DIR) \
		--ubuntu-version $(ubuntu_version) \
		--template-name $(ubuntu_template_name) \
		$(if $(instance_id),--instance-id $(instance_id),) \
		--instance-id-min $(instance_id_min) \
		--template-id-min $(template_id_min) \
		--template-id-max $(template_id_max) \
		--instance-name $(instance_name) \
		--script-revision $(timestamp) \
		--proxmox-user $(proxmox_user) \
		--proxmox-instance $(proxmox_instance) \
		--terraform-extra-args "$(TF_ARGS)"

terraform-destroy: ## Destroy Proxmox instance
	@venv/bin/python scripts/terraform.py destroy \
		--terraform-dir $(TERRAFORM_DIR) \
		--ubuntu-version $(ubuntu_version) \
		--template-name $(ubuntu_template_name) \
		$(if $(instance_id),--instance-id $(instance_id),) \
		--instance-id-min $(instance_id_min) \
		--template-id-min $(template_id_min) \
		--template-id-max $(template_id_max) \
		--instance-name $(instance_name) \
		--script-revision $(timestamp) \
		--proxmox-user $(proxmox_user) \
		--proxmox-instance $(proxmox_instance) \
		--terraform-extra-args "$(TF_ARGS)"

terraform-clear-state: ## Clear Terraform state
	@venv/bin/python scripts/terraform.py clear-state --terraform-dir $(TERRAFORM_DIR)

lint: ## Lint Python scripts with ruff
	@venv/bin/python -m ruff check scripts/*.py
	@venv/bin/python -m ruff format scripts/*.py

help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
