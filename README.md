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

* All-in entrypoint (typical run):

  ```bash
  ansible-playbook -i inventories/lab/hosts.ini playbooks/site.yml
  ```
* Target just NetBox hosts:

  ```bash
  ansible-playbook -i inventories/lab/hosts.ini playbooks/netbox.yml -l netbox
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

## 🧭 Legacy notes (from the original README)

These were preserved for reference and may be superseded by the role-based layout above.

* **Bootstrap a system**
  *First: edit the bootstrap file and add the IP of the target*
  *NOTE: This allows bootstrapping without the remote user having sudoers NOPASSWD configured*

  ```bash
  ansible-playbook -i bootstrap playbooks/bootstrap.yml --ask-become-pass --ask-pass
  ```

* **System baseline (all systems)**

  ```bash
  ansible-playbook playbooks/baseline.yml
  ```

* **System baseline (single host)**

  ```bash
  ansible-playbook playbooks/baseline.yml -l buntu04 --ask-become-pass
  ```

---

## 📜 License

MIT
