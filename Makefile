# TODO this is stretching make a bit
.ONESHELL:
.SHELLFLAGS = -ecuo pipefail
.PHONY: packer

packer:
	cd packer
	packer build main.pkr.hcl

tfapply:
	cd terraform
	terraform apply

ssh_unsafe:
	ssh \
		-o StrictHostKeyChecking=no \
		-o UserKnownHostsFile=/dev/null \
		-p $(shell cd terraform && terraform output -raw ssh_port) \
		rogryza@$(shell cd terraform && terraform output -raw ip)
