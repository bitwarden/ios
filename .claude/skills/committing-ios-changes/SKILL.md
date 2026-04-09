---
name: committing-ios-changes
description: Commit changes, stage files, or create a commit for Bitwarden iOS. Use when asked to "commit", "stage changes", "create commit", "git commit", or when ready to record changes to git history.
---

# Committing iOS Changes

## Pre-commit Check

Before committing, verify the preflight checklist is complete.
If not done: invoke `perform-ios-preflight-checklist` first.

## Commit Message Format

```
[PM-XXXXX] <type>: Brief description of what changed
```

- **Ticket**: `[PM-XXXXX]` or `[BWA-XXX]` — required
- **Type**: one of `feat`, `fix`, `bug`, `chore`, `refactor`, `test`, `docs`, `llm`
- **Description**: imperative mood, lowercase after colon, no period at end
- PR number is appended automatically by GitHub on merge: `(#2399)`

### Type Guide

| Type | Use when |
|------|----------|
| `feat` | New user-visible feature |
| `fix` | Bug fix |
| `bug` | Bug fix (alternate convention used in this repo) |
| `chore` | Maintenance, dependency update, build change |
| `refactor` | Code restructuring without behavior change |
| `test` | Adding or updating tests only |
| `docs` | Documentation only |
| `llm` | LLM-related changes (CLAUDE.md, skills, prompts) |

### Examples from git log
```
[PM-32221] chore: Add appcontext to crashlytics
[PM-31470] bug: Show migrate personal vault on unlock
[PM-33136] fix: Centralize TOTP key error handling to reduce Crashlytics noise
[PM-31836] bug: Create Passkeys into MyItems
```

## What to Stage

Stage specific files — avoid `git add -A` or `git add .`:

```bash
git add BitwardenShared/UI/Auth/Login/LoginProcessor.swift
git add BitwardenShared/UI/Auth/Login/LoginProcessorTests.swift
```

## What NOT to Commit

- Files containing credentials, API keys, or secrets
- Build artifacts (`.build/`, `DerivedData/`, `.xcodeproj/` — already gitignored)
- Unintended changes to `project-*.yml` (verify these are intentional)
- Snapshot test images unless your PR intentionally changes UI

## Create the Commit

```bash
git commit -m "$(cat <<'EOF'
[PM-XXXXX] <type>: Your commit message here
EOF
)"
```
