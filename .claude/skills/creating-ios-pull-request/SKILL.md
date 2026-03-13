---
name: creating-ios-pull-request
description: Create a pull request, open a PR, or submit a PR for Bitwarden iOS changes. Use when asked to "create PR", "open pull request", "submit PR", "push and open PR", or when work is ready for review.
---

# Creating an iOS Pull Request

## Prerequisites

- All commits are in place
- Preflight checklist complete (`perform-ios-preflight-checklist`)
- Branch is pushed to remote: `git push -u origin <branch-name>`

## PR Title Format

Match the commit format:
```
[PM-XXXXX] <type>: Brief description
```

Keep under 70 characters. GitHub appends the PR number on merge.

## PR Body

Use the repo's `.github/PULL_REQUEST_TEMPLATE.md` structure:

```markdown
## 🎟️ Tracking
[PM-XXXXX](https://bitwarden.atlassian.net/browse/PM-XXXXX)

## 📔 Objective
[1-3 sentences: what this PR does and why]

## 📸 Screenshots
[Required for UI changes. Use fixed-width images. Delete section if not applicable.]
```

## Create as Draft

```bash
gh pr create \
  --draft \
  --base main \
  --title "[PM-XXXXX] <type>: Brief description" \
  --body "$(cat <<'EOF'
## 🎟️ Tracking
[PM-XXXXX](https://bitwarden.atlassian.net/browse/PM-XXXXX)

## 📔 Objective
[Description]
EOF
)"
```

Always create as `--draft`. Mark ready for review only after self-review.

## After Creating

1. Add labels via `labeling-ios-changes` skill
2. Self-review using `reviewing-changes` skill
3. Mark ready for review when satisfied
