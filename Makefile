# ONF Aether Ansbile Makefile
#
# SPDX-FileCopyrightText: © 2020 Open Networking Foundation <support@opennetworking.org>
# SPDX-License-Identifier: Apache-2.0

# Use bash for pushd/popd, and to fail quickly.
# No -u as virtualenv activate script has undefined vars
SHELL = bash -e -o pipefail

# tooling
VIRTUALENV        ?= python3 -m venv

# ansible files is all top-level playbooks
ANSIBLE_PLAYBOOKS ?= $(wildcard *.yml)

# YAML files, excluding venv and cookiecutter directories
YAML_FILES        ?= $(shell find . -type d \( -path "./venv_onfansible" -o -path "./cookiecutters" -o -path "./ansible_collections" -o -path "./roles" -o -path "./inventory/host_vars" \) -prune -o -type f \( -name '*.yaml' -o -name '*.yml' \) -print )

# all files with extensions
PYTHON_FILES      ?= $(wildcard scripts/*.py scripts/*/*.py filter_plugins/*.py lint_rules/*.py cookiecutters/*/hooks/*.py)

.DEFAULT_GOAL := help
.PHONY: test lint yamllint ansiblelint license help

# Create the virtualenv with all the tools installed
VENV_NAME = venv_onfansible

$(VENV_NAME): requirements.txt
	$(VIRTUALENV) $@ ;\
  source ./$@/bin/activate ; set -u ;\
  python -m pip install --upgrade pip;\
  python -m pip install -r requirements.txt
	echo "To enter virtualenv, run 'source $@/bin/activate'"

galaxy: $(VENV_NAME) galaxy.yml ## Download ansible galaxy provided collection and roles
	source ./$</bin/activate ; set -u ;\
	ansible-galaxy collection install -r galaxy.yml

license: $(VENV_NAME) ## Check license with the reuse tool
	source ./$</bin/activate ; set -u ;\
  reuse --version ;\
  reuse --root . lint

# Cookiecutter tests
test: ansiblelint flake8 pylint black ## run all standard tests

yamllint: $(VENV_NAME) ## lint YAML format using yamllint
	source ./$</bin/activate ; set -u ;\
  yamllint --version ;\
  yamllint \
	-d "{extends: default, rules: {line-length: {max: 99}}}" \
    -s $(YAML_FILES)

ansiblelint: $(VENV_NAME) ## lint ansible-specific format using ansible-lint
	source ./$</bin/activate ; set -u ;\
  ansible-lint --version ;\
  ansible-lint -R -v $(ANSIBLE_PLAYBOOKS)

flake8: $(VENV_NAME) ## check python formatting with flake8
	source ./$</bin/activate ; set -u ;\
  flake8 --version ;\
  flake8 --max-line-length 99 --per-file-ignores="__init__.py:F401" $(PYTHON_FILES)

pylint: $(VENV_NAME) ## pylint check for python 3 compliance
	source ./$</bin/activate ; set -u ;\
  pylint --version ;\
  pylint --rcfile=pylint.ini $(PYTHON_FILES)

black: $(VENV_NAME) ## run black on python files in check mode
	source ./$</bin/activate ; set -u ;\
  black --version ;\
  black --check $(PYTHON_FILES)

blacken: $(VENV_NAME) ## run black on python files to reformat
	source ./$</bin/activate ; set -u ;\
  black --version ;\
  black $(PYTHON_FILES)

clean:
	rm -rf $(VENV_NAME) ansible_collections

help: ## Print help for each target
	@echo infra-playbooks make targets
	@echo
	@grep '^[[:alnum:]_-]*:.* ##' $(MAKEFILE_LIST) \
    | sort | awk 'BEGIN {FS=":.* ## "}; {printf "%-25s %s\n", $$1, $$2};'
