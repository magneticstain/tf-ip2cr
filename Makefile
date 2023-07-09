# Makefile for Terraform

# Set the Terraform directory and backend configuration
TF_BACKEND_CONFIG = ./backend.tfvars

.PHONY: init plan apply destroy

init:
	terraform init -backend-config=$(TF_BACKEND_CONFIG)

plan:
	$(MAKE) init
	terraform plan

apply:
	$(MAKE) init
	terraform apply

destroy:
	$(MAKE) init
	terraform destroy
