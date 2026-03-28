.PHONY: help init init-dev init-prod fmt validate lint plan apply destroy test

ENV ?= prod

help:
	@echo "Usage: make <target> [ENV=dev|prod]"
	@echo ""
	@echo "Targets:"
	@echo "  init        Initialise Terraform with backend.hcl"
	@echo "  init-dev    Initialise and select/create the dev workspace"
	@echo "  init-prod   Initialise and select/create the prod workspace"
	@echo "  fmt         Format all .tf files in place"
	@echo "  validate    Validate configuration (no backend needed)"
	@echo "  lint        Run tflint with AWS rules"
	@echo "  plan        Preview changes (uses envs/\$(ENV).tfvars)"
	@echo "  apply       Apply changes (uses envs/\$(ENV).tfvars)"
	@echo "  destroy     Destroy all resources (uses envs/\$(ENV).tfvars)"
	@echo "  test        Run terraform test suite (Terraform 1.7+)"

init:
	terraform init -backend-config=backend.hcl

init-dev:
	terraform init -backend-config=backend.hcl
	terraform workspace select dev 2>/dev/null || terraform workspace new dev

init-prod:
	terraform init -backend-config=backend.hcl
	terraform workspace select prod 2>/dev/null || terraform workspace new prod

fmt:
	terraform fmt -recursive

validate:
	terraform init -backend=false -reconfigure
	terraform validate

lint:
	tflint --init --config .tflint.hcl
	tflint --recursive --config "$(CURDIR)/.tflint.hcl"

plan:
	terraform plan -var-file=envs/$(ENV).tfvars

apply:
	terraform apply -var-file=envs/$(ENV).tfvars

destroy:
	@echo "WARNING: This will destroy all resources in $(ENV)."
	@read -p "Type 'yes' to confirm: " confirm && [ "$$confirm" = "yes" ]
	terraform destroy -var-file=envs/$(ENV).tfvars

test:
	terraform test
