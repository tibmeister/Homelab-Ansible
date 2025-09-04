# Defaults
INVENTORY ?= inventories/lab/hosts.ini
PLAY ?= playbooks/site.yml
LIMIT ?=
TAGS ?=
ANSIBLE ?= ansible-playbook
YAMLLINT ?= yamllint
ANSIBLE_LINT ?= ansible-lint
VAULT_FILE ?= inventories/lab/group_vars/vault.yml
VAULT_PASS ?=

# Optional vault arg if VAULT_PASS is provided
ifdef VAULT_PASS
VAULT_ARG=--vault-password-file $(VAULT_PASS)
endif

.PHONY: run check syntax lint pre-commit ping netbox vault-edit vault-view vault-rekey

run:
	$(ANSIBLE) -i $(INVENTORY) $(PLAY) $(VAULT_ARG) $(if $(LIMIT),-l $(LIMIT),) $(if $(TAGS),-t $(TAGS),)

check:
	$(ANSIBLE) -i $(INVENTORY) $(PLAY) --check $(VAULT_ARG) $(if $(LIMIT),-l $(LIMIT),) $(if $(TAGS),-t $(TAGS),)

syntax:
	$(ANSIBLE) -i $(INVENTORY) --syntax-check $(PLAY)

lint:
	$(YAMLLINT) .
	$(ANSIBLE_LINT)

pre-commit:
	pre-commit run --all-files

ping:
	ansible -i $(INVENTORY) all -m ping

# Convenience target for the NetBox play
netbox:
	$(MAKE) run PLAY=playbooks/netbox.yml LIMIT=netbox

# Vault helpers
vault-edit:
	ansible-vault edit $(VAULT_FILE)

vault-view:
	ansible-vault view $(VAULT_FILE)

vault-rekey:
	ansible-vault rekey $(VAULT_FILE)
