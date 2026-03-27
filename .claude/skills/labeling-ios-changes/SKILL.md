---
name: labeling-ios-changes
description: Label a pull request, categorize changes, or add labels to a PR for Bitwarden iOS. Use when asked to "label PR", "add labels", "categorize changes", "what labels should I add", or after creating a PR.
---

# Labeling iOS Changes

Apply labels to categorize the change type and affected app(s).

## Change Type Label (pick one)

| Commit type | Label |
|-------------|-------|
| `feat` — user-facing feature | `t:feature-app` |
| `feat` — internal tool/automation | `t:feature-tool` |
| `fix` / `bug` | `t:bug` |
| `chore` / `refactor` / `test` | `t:tech-debt` |
| `docs` | `t:docs` |
| `llm` — LLM config, skills, prompts | `t:llm` |
| CI/workflow changes | `t:ci` |
| Dependency updates | `t:deps` |
| Misc | `t:misc` |
| Breaking change (add alongside type label) | `t:breaking-change` |

## App Context Label (pick one or both)

| App affected | Label |
|--------------|-------|
| Password Manager (`BitwardenShared/`, `Bitwarden/`) | `app:password-manager` |
| Authenticator (`AuthenticatorShared/`, `Authenticator/`) | `app:authenticator` |
| Both | `app:password-manager` + `app:authenticator` |

## Apply Labels

```bash
gh pr edit <PR_NUMBER> --add-label "t:feature-app,app:password-manager"
```

On the current branch (no PR number needed):
```bash
gh pr edit --add-label "t:bug,app:password-manager"
```

## Special Labels

| Label | When to use |
|-------|-------------|
| `ai-review` | Request a Claude code review via CI |
| `automated-pr` | PR created by automation or workflow |
| `hold` | Prevent merge — add when PR should not be merged yet |
| `needs-qa` | QA review required before merge |
