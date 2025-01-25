PACKER_DIR := ./packer
PACKER_DEBUG := ""
PACKER_ARGS := ""

.PHONY: help

default: help

packer-build: ## Build Proxmox template
	cd $(PACKER_DIR); \
	packer build -var-file=credentials.pkr.hcl  ubuntu.pkr.hcl $(PACKER_ARGS)

packer-validate: ## Validate Packer configuration
	cd $(PACKER_DIR); \
	packer validate -var-file=credentials.pkr.hcl  ubuntu.pkr.hcl $(PACKER_ARGS)

help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)