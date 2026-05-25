PACKER_DIR := ./packer
TERRAFORM_DIR := ./terraform
ISO_DIR := ./iso

# Terraform Vars
instance_id=203
instance_name="ubuntu-instance-03"
timestamp=`date +%s`

# Ubuntu ISO Vars
ubuntu_version=26.04
ubuntu_iso_name=ubuntu-$(ubuntu_version)-live-server-amd64.iso
ubuntu_iso_url=https://releases.ubuntu.com/$(ubuntu_version)/$(ubuntu_iso_name)
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

packer-build: ## Build Proxmox template
	@cd $(PACKER_DIR); \
	packer build -var-file=credentials.pkr.hcl  ubuntu.pkr.hcl $(PACKER_ARGS)

packer-validate: ## Validate Packer configuration
	@cd $(PACKER_DIR); \
	packer validate -var-file=credentials.pkr.hcl  ubuntu.pkr.hcl $(PACKER_ARGS)

terraform-plan: ## Generate a TF plan
	@cd $(TERRAFORM_DIR); \
	terraform plan --var instance_id=$(instance_id) --var instance_name=$(instance_name) --var script_revision=$(timestamp) $(TF_ARGS)

terraform-provision: ## Provision Proxmox instance
	@cd $(TERRAFORM_DIR); \
	terraform apply --var instance_id=$(instance_id) --var instance_name=$(instance_name) --var script_revision=$(timestamp) -auto-approve $(TF_ARGS)

terraform-destroy: ## Destroy Proxmox instance
	@cd $(TERRAFORM_DIR); \
	terraform destroy --var instance_id=$(instance_id) --var instance_name=$(instance_name) --var script_revision=$(timestamp) $(TF_ARGS)

terraform-clear-state: ## Clear Terraform state
	@cd $(TERRAFORM_DIR); \
	rm *.tfstate *tfstate.backup

help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
