# sriov Makefile
#
# SPDX-FileCopyrightText: © 2021 Open Networking Foundation <support@opennetworking.org>
# SPDX-License-Identifier: Apache-2.0

SHELL = bash -eu -o pipefail

.DEFAULT_GOAL := help
.PHONY: test lint yamllint ansiblelint license help

test: ## run tests on the playbook with molecule
	molecule --version
	molecule test

lint: yamllint ansiblelint ## run all lint checks

# all YAML files
YAML_FILES ?= $(shell find . -type f \( -name '*.yaml' -o -name '*.yml' \) -print )

yamllint: ## lint check with yamllint
	yamllint --version
	yamllint \
    -d "{extends: default, rules: {line-length: {max: 99}}}" \
    -s $(YAML_FILES)

# List of molecule files, not including base molecule.yml which isn't ansible format
MOLECULE_FILES ?= $(shell find molecule -type f -name '*.yml' \! -name 'molecule.yml' -print )

ansiblelint: ## lint check with ansible-lint
	ansible-lint --version
	ansible-lint -v .
	ansible-lint -v $(MOLECULE_FILES)

license: ## Check license with the reuse tool
	reuse --version
	reuse --root . lint

help: ## Print help for each target
	@echo sriov test targets
	@echo
	@grep '^[[:alnum:]_-]*:.* ##' $(MAKEFILE_LIST) \
    | sort | awk 'BEGIN {FS=":.* ## "}; {printf "%-25s %s\n", $$1, $$2};'
