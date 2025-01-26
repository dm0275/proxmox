PACKER_DIR := ./packer
TERRAFORM_DIR := ./terraform

# Terraform Vars
instance_id=203
instance_name="ubuntu-instance-03"
timestamp=`date +%s`

.PHONY: help

default: help

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

terraform-clear-state: ## Clear Terraform state
	@cd $(TERRAFORM_DIR); \
	rm *.tfstate *tfstate.backup

help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)