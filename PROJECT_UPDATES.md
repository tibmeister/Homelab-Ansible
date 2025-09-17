# Project Updates

> Purpose: Running log of design decisions, refactors, risk notes, and context summaries that the ChatGPT Project should “see.”

## How This File Is Used
- This file is the canonical conversation context shared between your editor and the ChatGPT Project.
- At session start:
  - Agent loads this file into memory and skims the latest entries to recover context and pending follow‑ups.
  - Agent confirms any open items with you before doing work.
- During a session:
  - When a decision is made or a refactor lands, capture a brief note (to be finalized at session end).
  - Prefer linking to exact file paths and concise summaries over long diffs.
- At session end:
  - Append a new dated entry using the template below.
  - Update the Index with a new bullet linking to the entry title.
  - Keep entries short, scannable, and in reverse‑chronological order.

## Conventions
- Use date-based headings: `YYYY-MM-DD` (UTC) as the section title.
- Keep the update title short and descriptive.
- Prefer one entry per logical change or decision.
- Suggested section template:

```markdown
## [YYYY-MM-DD] Title of update
- Summary: one or two sentences on what changed/decided.
- Why: brief rationale or context.
- Scope: what areas/hosts/environments it touches.
- Affected files: key paths edited/added/removed.
- Risks/guardrails: lockout, data loss, or rollout cautions.
- Follow-ups: next steps, TODOs, or open questions.
```

## Index
- [2025-09-17] Documentation: Firewall enablement & rules guidance
- [2025-09-17] Single entrypoint with bootstrap + baseline
- [2025-09-17] Inventory as SSH user source of truth
- [2025-09-17] Baseline (common role) implemented
- [2025-09-17] Optional firewall framework (UFW/firewalld)
- [2025-09-17] Lint and FQCN normalization

---

## [2025-09-17] Single entrypoint with bootstrap + baseline
- Combined flow in `playbooks/site.yml`: bootstrap (hosts in `[bootstrap]`) → baseline (`hosts: all`) → NetBox (`hosts: netbox`).
- Kept `[bootstrap]` group to explicitly onboard new hosts. Idempotent if left in, but recommended to remove once onboarded.
- Bootstrap ensures Python/sudo, creates `ansible` user, deploys SSH keys, and grants passwordless sudo via `/etc/sudoers.d/ansible`.

## [2025-09-17] Inventory as SSH user source of truth
- Removed `remote_user` from plays.
- Set `[all:vars] ansible_user=ansible` in `inventories/lab/hosts.ini` so inventory defines the default user.
- CLI can still override for first-time runs (`-u <bootstrap_user>` with `--ask-pass --ask-become-pass`).

## [2025-09-17] Baseline (common role) implemented
- Data-driven users/groups/sudo/authorized_keys with safe defaults and override hooks.
- Packages with per-OS name overrides (e.g., RHEL `vim-enhanced`). Debian extras: remove `vim-tiny`, set update-alternatives to Vim.
- SSH policy (PermitRootLogin, PasswordAuthentication, optional KEX/Ciphers/MACs) with reload handlers.
- Time sync via Chrony + timezone set (`community.general.timezone`), OS-aware service/paths.
- Sysctl via `/etc/sysctl.d/90-common-baseline.conf` + immediate apply.
- Unattended updates: Debian (`unattended-upgrades`) and RHEL (`dnf-automatic.timer`).

## [2025-09-17] Optional firewall framework (UFW/firewalld)
- Disabled by default (`common_firewall_enabled: false`). Package install gated by `common_firewall_manage_packages`.
- UFW (Debian): default incoming/outgoing policies; extra rules via `common_firewall_rules_ufw` (rule/name/port/proto/comment).
- Firewalld (RHEL): default `public` zone; extra rules via `common_firewall_rules_firewalld` (rule/service/port/proto/zone).
- Commented examples added to `inventories/lab/group_vars/all/main.yml` for easy enablement.

## [2025-09-17] Lint and FQCN normalization
- Use canonical FQCNs for non-builtin modules (e.g., `community.general.timezone`, `ansible.posix.*`, `community.general.*`).
- Jinja spacing/style normalized in firewall expressions to satisfy ansible-lint.

## [2025-09-17] Documentation: Firewall enablement & rules guidance
- Summary: README now documents how to enable the optional firewall baseline and define rules for both UFW and firewalld.
- Why: Make the framework safe to adopt later with clear, copy‑pastable examples and guardrails.
- Scope: README; variables under `inventories/lab/group_vars/all/main.yml`.
- Affected files: README.md (new Firewall section); inventories/lab/group_vars/all/main.yml (commented samples).
- Risks/guardrails: Feature is off by default; package install is gated. SSH remains allowed by default.
- Follow-ups: If additional rule schemas are needed (e.g., rich rules, interfaces), extend variables and tasks accordingly.

---

### Risk Notes / Guardrails
- SSH lockout risk: leave `bootstrap_disable_password_auth: false` until key-based login as `ansible` is verified.
- Firewall: framework is opt-in; enabling without proper rules can block services. Ensure SSH stays allowed.
- Symlinked repo path: prefer running from repo root; paths in `ansible.cfg` are relative and safe for symlinks.
- Vault: keep secrets only in `inventories/lab/group_vars/all/vault.yml`; use `--ask-vault-pass` or a vault password file.
