# Contributing Guidelines

Thanks for your interest in contributing to **Homelab-Ansible**!
This project is public for transparency and sharing, but contributions follow a structured workflow.

---

## 🪢 Branching Strategy

- `main` branch is **protected**. No direct pushes.
- Create feature branches for all work:
  ```bash
  git checkout -b feature/my-change
  ```

Suggested naming conventions:
- `feature/<short-description>` — new roles, playbooks, or enhancements
- `fix/<short-description>` — bugfixes or corrections
- `docs/<short-description>` — documentation-only changes

---

## 🔀 Pull Requests

1. Ensure your branch is up to date with `main`.
2. Push changes and open a PR.
3. PRs must:
   - Pass **CI checks** (`ansible-lint`, `yamllint`)
   - Be reviewed & approved before merge

---

## ✅ Commit Messages

Use clear, descriptive commit messages:
- Good: `Add NetBox role for native deployment`
- Bad: `fix stuff`

If multiple related commits exist, consider squashing before merge.

---

## 📂 Adding New Playbooks or Roles

- Playbooks go in `ansible/playbooks/`
- Roles go in `ansible/roles/` (init with `ansible-galaxy init`)
- Import into `site.yml` if they should be part of the main run

---

## 🔐 Secrets & Vault

- Never commit plaintext secrets.
- Always use `ansible-vault` for sensitive variables.
- Only encrypted files belong in Git.

---

## 🖥️ Local Overrides

- Use `hosts.local.ini` and `*.local.yml` for lab-specific credentials/IPs.
- These files are ignored by Git and never leave your workstation.

---

## 🧹 Pre-Commit Hooks

This repo supports [pre-commit](https://pre-commit.com/) to enforce consistency.

Install once:
```bash
pipx install pre-commit
pre-commit install
```

---

## 🙌 Code of Conduct

- Keep contributions professional and constructive.
- PRs are reviewed with an eye toward maintainability, security, and clarity.

---

By contributing, you agree to follow these guidelines and respect the security model of this project.
