# Changelog

All notable changes to this project will be documented in this file.

## 2025-09-17

- Combine entrypoint into a single site playbook that runs:
  - Bootstrap (hosts in `[bootstrap]` only)
  - Baseline (`roles/common`) on `hosts: all`
  - NetBox role on `netbox`
- Establish inventory as source of truth for SSH user
  - Removed `remote_user` from plays
  - Set `[all:vars] ansible_user=ansible` in `inventories/lab/hosts.ini`
- Bootstrap role improvements
  - Ensure passwordless sudo for `ansible` via `/etc/sudoers.d/ansible`
  - `bootstrap_ansible_nopasswd` default added
- Common (baseline) role scaffolding and implementation
  - Implemented data‑driven users/groups/sudo/authorized_keys
  - Implemented packages with per‑OS overrides (`vim` → `vim-enhanced` on RHEL)
  - Debian extras: remove `vim-tiny` and set update‑alternatives to Vim
  - Implemented SSH policy management (PermitRootLogin, PasswordAuthentication, optional KEX/Ciphers/MACs)
  - Implemented time sync (Chrony) + timezone with `community.general.timezone`
  - Implemented sysctl management via `/etc/sysctl.d/90-common-baseline.conf`
  - Implemented unattended updates
    - Debian: `unattended-upgrades`
    - RHEL: `dnf-automatic` + timer
  - Implemented optional firewall framework (off by default)
    - Debian: UFW defaults + extra rules list
    - RHEL: firewalld defaults + extra rules list
    - Added `common_firewall_manage_packages` to gate package installation
- Inventory examples
  - Added commented firewall blocks in `inventories/lab/group_vars/all/main.yml`
- Documentation updates
  - Added first‑time vs regular runs with `--ask-vault-pass` and bootstrap flags
  - Added Control Station bootstrap instructions
  - Added Firewall section with how to enable and define rules
  - Added Bootstrap Group vs Baseline section
- Linting/quality
  - Switched to canonical `community.general.timezone`
  - Jinja spacing/style cleanups in firewall tasks
