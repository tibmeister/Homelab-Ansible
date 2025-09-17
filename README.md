# Homelab-Ansible

[![Lint](https://github.com/tibmeister/Homelab-Ansible/actions/workflows/lint.yml/badge.svg?branch=main)](https://github.com/tibmeister/Homelab-Ansible/actions/workflows/lint.yml)

Ansible repository for managing my homelab infrastructure. This repo is structured for clarity, maintainability, and safe public sharing.

---

## 📂 Repository Layout

```
.
├── ansible.cfg                # Core Ansible configuration
├── inventories/
│   └── lab/
│       ├── hosts.ini          # Public inventory (hostnames/FQDNs only)
│       ├── hosts.local.ini    # Local override with IPs/credentials (gitignored)
│       └── group_vars/
│           └── all/
│               └── vault.yml  # Encrypted variables (Ansible Vault)
├── playbooks/
│   ├── site.yml               # Entrypoint play
│   └── netbox.yml             # Example play for NetBox role
└── roles/
    ├── common/                # Base OS config role (example/custom)
    └── netbox_native/         # NetBox native VM setup role
```

* **Custom roles** are versioned here. Galaxy-installed roles are not committed by default.
* Real IPs/creds live in `hosts.local.ini` and `*.local.yml` and are **not** committed.

---

## 🔐 Using Ansible Vault

Sensitive data (passwords, API tokens, keys) must be stored in vault-encrypted files.

* Encrypt a file:

  ```bash
  ansible-vault encrypt inventories/lab/group_vars/all/vault.yml
  ```
* Edit the vault:

  ```bash
  ansible-vault edit inventories/lab/group_vars/all/vault.yml
  ```
* Run with a prompt for the vault password:

  ```bash
  ansible-playbook playbooks/site.yml --ask-vault-pass
  ```

> **Tip:** Encrypted vault files can be committed safely. Never commit plaintext copies.

---

## 🖥️ Local inventory override (`hosts.local.ini`)

Use `hosts.local.ini` for lab-specific details (real IPs, credentials). This file is ignored by Git.

**Example (`inventories/lab/hosts.local.ini`):**

```ini
[netbox]
10.27.200.18 ansible_user=admin ansible_password=supersecret

[mus-netservice]
10.27.200.61 ansible_user=admin ansible_password=supersecret
10.27.200.62 ansible_user=admin ansible_password=supersecret
```

**Keep `hosts.ini` public and generic:**

```ini
[netbox]
mus-netbox-1

[mus-netservice]
mus-netservice-1
mus-netservice-2
```

---

## ▶️ Running plays

### Install Galaxy collections (once or when updated)

```bash
ansible-galaxy install -r collections/requirements.yml
```

### First-time bootstrap of a new host

The site entrypoint runs three plays in order: bootstrap → baseline (common) → NetBox (on `netbox` group).

Use a temporary/initial login for the very first run, and prompt for vault and sudo passwords:

```bash
ansible-playbook playbooks/site.yml \
  -i inventories/lab/hosts.ini \
  -l <hostname> \
  -u <bootstrap_user> \
  --ask-pass \
  --ask-become-pass \
  --ask-vault-pass
```

What happens:
- Bootstrap ensures Python/sudo, creates the `ansible` user, installs its SSH authorized_keys, and grants passwordless sudo via `/etc/sudoers.d/ansible`.
- Baseline then reconnects as `ansible` using key-based auth (no sudo password required).

Tip: If your SSH key isn’t the default, add `--private-key ~/.ssh/<key>`.

### Regular baseline runs (after bootstrap)

```bash
ansible-playbook playbooks/site.yml \
  -i inventories/lab/hosts.ini \
  --ask-vault-pass
```

Target a subset:

```bash
ansible-playbook playbooks/site.yml -i inventories/lab/hosts.ini -l netbox --ask-vault-pass
```

Optional hardening: once you’ve confirmed key-based login works, you can disable SSH password auth by setting `bootstrap_disable_password_auth: true` in inventory and re-running.

### Control station bootstrap (your Ansible host)

If you need to (re)provision your control node (install Ansible tooling and/or deploy your SSH keypair from Vault):

```bash
ansible-playbook playbooks/control_station_bootstrap.yml \
  -i inventories/lab/hosts.ini \
  -l control \
  --ask-vault-pass [--ask-become-pass]
```

---

## ➕ Adding new playbooks & roles

1. Create a playbook under `playbooks/` (e.g., `playbooks/thing.yml`).
2. Create roles with:

   ```bash
   ansible-galaxy init roles/<role_name>
   ```
3. Reference the role from your play or from `site.yml`.
4. Keep tasks, templates, and handlers **inside roles** for reusability.
5. Test with your local overrides, then open a PR.

---

## 🔄 Branch protection & PR workflow

* `main` is **protected**. No direct pushes.
* Work on feature branches, open PRs, and require passing checks:

  * GitHub Actions: `ansible-lint`, `yamllint`
  * Optional code review (recommended even for solo projects)
* Merge via squash or rebase for clean history.

---

## 🧪 Linting & CI

* **Local hooks:** `pre-commit` runs `end-of-file-fixer`, `trailing-whitespace`, `yamllint`, and `ansible-lint`.

  ```bash
  pipx install pre-commit  # or pip install --user pre-commit
  pre-commit install
  pre-commit run --all-files
  ```
* **CI:** `.github/workflows/lint.yml` runs the same checks on each push/PR.

---

## 🔁 Symlink note (repo path)

This repo is often accessed via a symlink:

```
/nfs/swarm/ansible  ->  ~/ansible
```

To keep behavior consistent whether you run from the real path or the symlink:

* Use **relative** paths in `ansible.cfg`:

  ```ini
  [defaults]
  inventory = inventories/lab/hosts.ini
  roles_path = roles:playbooks/roles:~/.ansible/roles:/usr/share/ansible/roles:/etc/ansible/roles
  ```
* Always run from the **repo root** (either `/nfs/swarm/ansible` or `~/ansible`).

If running from elsewhere, force the config:

```bash
ANSIBLE_CONFIG=/nfs/swarm/ansible/ansible.cfg \
ANSIBLE_ROLES_PATH=/nfs/swarm/ansible/roles:/nfs/swarm/ansible/playbooks/roles \
ansible-playbook -i /nfs/swarm/ansible/inventories/lab/hosts.ini \
  /nfs/swarm/ansible/playbooks/site.yml
```

---

## 🔒 Security notes

* Never commit decrypted vaults or raw secrets.
* Keep `hosts.local.ini` and `*.local.yml` out of version control.
* Public repo is safe when secrets are encrypted or replaced with hostnames.

---

## 🧭 Bootstrap and baseline workflow

This repository uses a single entrypoint (`playbooks/site.yml`) that:
- Bootstraps brand-new hosts (no Python, no `ansible` user yet).
- Applies the baseline (`roles/common`) as the `ansible` user with key-based auth and passwordless sudo.
- Optionally deploys the NetBox stack to the `netbox` group.

Key inventory variables to set (examples live in `inventories/lab/group_vars/all/main.yml`):
- `ansible_password_hash: "{{ vault_ansible_password_hash }}"`
- `ansible_authorized_keys: "{{ vault_ansible_authorized_keys }}"`
- `bootstrap_disable_password_auth: false` (set to `true` after verifying key-based login)

Secrets belong in `inventories/lab/group_vars/all/vault.yml` (edit with `ansible-vault edit ...`) and you should include `--ask-vault-pass` in your playbook runs unless you’ve set `ANSIBLE_VAULT_PASSWORD_FILE`.

---

## 🔥 Firewall Baseline (optional, opt-in)

The `common` role includes a firewall framework that works across Debian (UFW) and RHEL (firewalld). It is disabled by default to avoid surprises.

Enable it by setting inventory vars (YAML shown; you can also set these in `hosts.ini` under `[all:vars]` or group-specific):

```yaml
# inventories/lab/group_vars/all/main.yml
---
# Turn on the firewall baseline
common_firewall_enabled: true

# Install firewall packages too (set true if hosts don't already have them)
common_firewall_manage_packages: true
```

Debian (UFW) defaults and extra rules

```yaml
# Default policies (applied when enabled)
common_firewall_ufw_default_incoming_policy: deny
common_firewall_ufw_default_outgoing_policy: allow

# Extra UFW rules (examples)
common_firewall_rules_ufw:
  - rule: allow
    name: OpenSSH            # UFW app profile (keeps SSH open)
  - rule: allow
    port: 8080
    proto: tcp
    comment: "App on 8080"
```

RHEL (firewalld) zone and extra rules

```yaml
# Default zone
common_firewall_zone_firewalld: public

# Extra firewalld rules (examples)
common_firewall_rules_firewalld:
  - rule: allow
    service: ssh            # enables service in the chosen zone
  - rule: allow
    port: 8080
    proto: tcp
    zone: public
```

Notes
- Nothing runs until `common_firewall_enabled: true`.
- Package installation only happens if `common_firewall_manage_packages: true`.
- UFW tasks set the default incoming/outgoing policies and keep SSH allowed.
- Firewalld tasks ensure the daemon is running (packages optional) and keep SSH allowed.
- Collections required: `community.general` and `ansible.posix` (install via `ansible-galaxy install -r collections/requirements.yml`).

---

## 🪜 Bootstrap Group vs Baseline

This repo intentionally keeps a dedicated `[bootstrap]` inventory group separate from the baseline.

- Purpose
  - `[bootstrap]`: Onboarding queue. Only these hosts run the first play which installs Python/sudo, creates the `ansible` user with SSH keys, and grants passwordless sudo.
  - Baseline: Not a group. The second play targets `hosts: all` and applies the `common` role to every host, every run.

- How to use
  - Add a brand‑new host to `[bootstrap]` (and any final groups) and run the site playbook with `-u <bootstrap_user> --ask-pass --ask-become-pass --ask-vault-pass`.
  - After it succeeds, optionally remove the host from `[bootstrap]`. It will continue to receive the baseline via `hosts: all`.

- Connection expectations
  - Bootstrap: connects with a temporary user (password auth ok) and runs `serial: 1` with facts off until Python is present.
  - Baseline: connects as `ansible` by default (set globally in `[all:vars] ansible_user=ansible`) using key‑based auth and passwordless sudo.

Keeping `[bootstrap]` separate avoids surprises and makes the onboarding flow explicit and safe.

## 🛠️ Makefile shortcuts

A small Makefile at the repo root makes common tasks fast:

```makefile
# Defaults
INVENTORY ?= inventories/lab/hosts.ini
PLAY ?= playbooks/site.yml
LIMIT ?=
TAGS ?=
ANSIBLE ?= ansible-playbook
YAMLLINT ?= yamllint
ANSIBLE_LINT ?= ansible-lint
VAULT_FILE ?= inventories/lab/group_vars/all/vault.yml
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
```

Quick examples:

```bash
make lint                         # yamllint + ansible-lint
make syntax                       # syntax-check default play
make run LIMIT=netbox             # run only against the netbox group
make run TAGS=install,certs       # run specific tags
make run VAULT_PASS=~/.ansible/vault_pass.txt   # use a vault password file
make netbox                       # shortcut: run playbooks/netbox.yml on netbox hosts
```

---

## 🔐 Adding or updating secrets in the Vault

Your vaulted vars live in `inventories/lab/group_vars/all/vault.yml`.

**Method A — edit the vault file (most common):**

```bash
make vault-edit
# or: ansible-vault edit inventories/lab/group_vars/all/vault.yml
```

Inside the file, add YAML keys as usual (one document, starting with `---`):

```yaml
---
cloudflare_api_token: "cf_XXXXXXXXXXXXXXXX"
db_password: "S3cureP@ss!"
```

Save & exit; the file remains encrypted at rest.

**Method B — add a single encrypted var from the CLI:**

```bash
ansible-vault encrypt_string 'S3cureP@ss!' --name 'db_password' \
  >> inventories/lab/group_vars/all/vault.yml
```

Then open the vault later to reorganize/clean up if needed (`make vault-edit`).

**Viewing (read-only):**

```bash
make vault-view
# or: ansible-vault view inventories/lab/group_vars/all/vault.yml
```

**Changing the vault password:**

```bash
make vault-rekey
# or: ansible-vault rekey inventories/lab/group_vars/all/vault.yml
```

> Tip: keep your vault password file out of Git (e.g., `~/.ansible/vault_pass.txt`) and pass it when needed:
>
> ```bash
> make run VAULT_PASS=~/.ansible/vault_pass.txt
> ```

---

## 📜 License

MIT

---

# CONTRIBUTING.md (copy into repo root)

````markdown
# Contributing Guidelines

Thanks for your interest in contributing to **Homelab-Ansible**!
This project is public for transparency and sharing, but contributions follow a structured workflow.

---

## 🪢 Branching Strategy

- `main` branch is **protected**. No direct pushes.
- Create feature branches for all work:
  ```bash
  git checkout -b feature/my-change
````

Suggested naming conventions:

* `feature/<short-description>` — new roles, playbooks, or enhancements
* `fix/<short-description>` — bugfixes or corrections
* `docs/<short-description>` — documentation-only changes

---

## 🔀 Pull Requests

1. Ensure your branch is up to date with `main`.
2. Push changes and open a PR.
3. PRs must:

   * Pass **CI checks** (`ansible-lint`, `yamllint`)
   * Be reviewed & approved before merge

---

## ✅ Commit Messages

Use clear, descriptive commit messages:

* Good: `Add NetBox role for native deployment`
* Bad: `fix stuff`

If multiple related commits exist, consider squashing before merge.

---

## 📂 Adding New Playbooks or Roles

* Playbooks go in `playbooks/`
* Roles go in `roles/` (init with `ansible-galaxy init roles/<role_name>`)
* Import roles from your play or from `site.yml` if they’re part of the main run

---

## 🔐 Secrets & Vault

* Never commit plaintext secrets.
* Always use `ansible-vault` for sensitive variables.
* Only **encrypted** files belong in Git.

---

## 🖥️ Local Overrides

* Use `hosts.local.ini` and `*.local.yml` for lab-specific credentials/IPs.
* These files are ignored by Git and never leave your workstation.

---

## 🧹 Pre-Commit Hooks

This repo supports [pre-commit](https://pre-commit.com/).

Install once:

```bash
pipx install pre-commit
pre-commit install
```

Run on all files:

```bash
pre-commit run --all-files
```

---

## 🙌 Code of Conduct

* Keep contributions professional and constructive.
* PRs are reviewed for maintainability, security, and clarity.

---

By contributing, you agree to follow these guidelines and respect the security model of this project.

````

---

# SECURITY.md (copy into repo root)

```markdown
# Security Policy

## Supported Branch
Only the `main` branch is supported. Use the latest commit for best results.

## Reporting a Vulnerability
If you believe you've found a security issue:
1. **Do not** open a public issue with sensitive details.
2. Email the repository owner or open a minimal issue asking for a secure contact.
3. Provide steps to reproduce, scope, and potential impact.

## Secrets Policy
- Never commit plaintext secrets (passwords, API tokens, SSH keys).
- All sensitive variables must be stored in **Ansible Vault**.
- Use `hosts.local.ini` and `*.local.yml` for lab-specific IPs/credentials; these files are ignored by Git.

## Dependency Security
- CI runs lint checks on every PR.
- Keep dependencies up-to-date. (Dependabot/ Renovate may be enabled later.)
````

---

# CODEOWNERS (copy into repo root)

```text
# Default owner for everything
* @tibmeister

# Explicit for Ansible tree
ansible/** @tibmeister
```

---

# .github/pull\_request\_template.md (optional but recommended)

```markdown
## Summary
Briefly describe the change and why it’s needed.

## Changes
- [ ] Item 1
- [ ] Item 2

## Testing
How did you test this? Commands, output, screenshots if relevant.

## Checklist
- [ ] `pre-commit run --all-files` passes
- [ ] CI checks (ansible-lint, yamllint) pass
- [ ] Docs updated (README/role README if applicable)
```
