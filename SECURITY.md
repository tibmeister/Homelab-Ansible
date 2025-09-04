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
- Keep dependencies up-to-date. Renovate/Dependabot may be enabled in the future.
