# ⚠️ CRITICAL SECURITY WARNING

## NEVER COMMIT API CREDENTIALS TO VERSION CONTROL!

This directory contains MCP (Model Context Protocol) configuration files that connect to external services like GitHub, Jira, and Confluence. These files are **TEMPLATES** that use environment variables for credentials.

## ❌ DO NOT DO THIS:

```json
{
  "env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_abc123def456ghi789..."  // ❌ NEVER DO THIS!
  }
}
```

## ✅ ALWAYS DO THIS:

```json
{
  "env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"  // ✅ Use environment variable
  }
}
```

## Why This Matters

**If you commit real API tokens:**
- Anyone with repository access can steal your credentials
- Automated bots scan GitHub for exposed tokens within minutes
- Your tokens can be used to:
  - Access private repositories
  - Modify issues and code
  - Steal sensitive data
  - Impersonate you

**Token exposure is a serious security incident that requires:**
1. Immediate token revocation
2. Security audit of affected accounts
3. Review of all actions taken with exposed token
4. Incident reporting to security team

## Proper Setup

### Recommended Approaches

**Option 1: Secrets Manager (Best Practice)**

Use a secrets management solution to store and retrieve credentials:
- ✅ Secrets never stored in plain text on disk
- ✅ Automatic rotation and expiration
- ✅ Audit logs of secret access
- ✅ Team-based access control
- ✅ Encrypted storage and transmission

Your secrets manager can inject environment variables at runtime, keeping credentials secure and centralized.

**Option 2: Environment Variables (Simpler)**

Store credentials in environment variables for basic security:
- ⚠️ Visible to any process you run
- ⚠️ May persist in shell history
- ⚠️ Manual rotation required

### Using Environment Variables

#### 1. Set Environment Variables

Add to your shell profile (`~/.bashrc`, `~/.zshrc`, or `~/.bash_profile`):

```bash
# GitHub
export GITHUB_TOKEN="ghp_your_token_here"

# Jira/Confluence
export JIRA_EMAIL="your-email@company.com"
export JIRA_API_TOKEN="your_atlassian_token_here"
```

#### 2. Reload Shell

```bash
source ~/.bashrc  # or source ~/.zshrc
```

#### 3. Verify Variables Are Set

```bash
echo $GITHUB_TOKEN     # Should show your token
echo $JIRA_API_TOKEN   # Should show your token
```

### Keep Config Files as Templates

Configuration files in this directory should **always** use the `${VAR_NAME}` syntax:

```json
{
  "env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}",
    "JIRA_EMAIL": "${JIRA_EMAIL}",
    "JIRA_API_TOKEN": "${JIRA_API_TOKEN}"
  }
}
```

## Before Every Commit

**ALWAYS review your changes before committing:**

```bash
# Check what you're about to commit
git diff --staged

# Look for patterns like these (DANGER SIGNS):
# - "ghp_" followed by letters/numbers (GitHub token)
# - "Bearer " followed by long strings
# - Email addresses with tokens
# - Any actual API keys or passwords
```

**If you see real credentials, immediately:**
```bash
# Unstage the file
git restore --staged .claude/mcp-servers/your-config.json

# Remove the credentials from the file
# Replace them with ${VAR_NAME} syntax
```

## .gitignore Protection

Consider adding patterns to `.gitignore` for credential files:

```gitignore
# MCP credential files (if you create separate credential configs)
.claude/mcp-servers/*credentials*.json
.claude/mcp-servers/*.local.json
.claude/mcp-servers/.env

# Environment files
.env
.env.local
*.credentials
*_credentials.json
```

## What If I Already Committed a Token?

**Act immediately:**

1. **Revoke the exposed token** (GitHub Settings → Developer Settings → Personal Access Tokens)
2. **Generate a new token** with minimal required permissions
3. **Audit recent activity** to see if token was used by others
4. **Notify your team/security** if in a corporate environment
5. **Remove from git history** (complex - see below)

### Remove from Git History (Advanced)

```bash
# WARNING: This rewrites history and affects all collaborators
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch .claude/mcp-servers/your-config.json" \
  --prune-empty --tag-name-filter cat -- --all

# Force push (coordinate with team first!)
git push origin --force --all
```

Better approach: Use tools like `git-secrets` or GitHub's secret scanning.

## Best Practices Summary

1. ✅ **Environment variables only** - Never hardcode credentials
2. ✅ **Template syntax** - Always use `${VAR_NAME}` in configs
3. ✅ **Review before commit** - Check `git diff --staged` every time
4. ✅ **Minimal permissions** - Give tokens only the access they need
5. ✅ **Regular rotation** - Change tokens every 90 days
6. ✅ **Separate tokens** - Different tokens for different projects
7. ✅ **No sharing** - Each team member should have their own tokens

## Additional Resources

- **MCP Configuration Guide**: `MCP_CONFIGURATION_GUIDE.md` - Complete setup instructions with security details
- **Integration Quickstart**: `MCP_INTEGRATION_QUICKSTART.md` - Fast setup guide
- **GitHub Token Management**: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token
- **Atlassian API Tokens**: https://support.atlassian.com/atlassian-account/docs/manage-api-tokens-for-your-atlassian-account/

---

## Summary

🔒 **Keep credentials in environment variables**
📝 **Keep config files as templates with ${VAR_NAME}**
👀 **Review every commit carefully**
🚫 **Never commit real API tokens**

**When in doubt, ask!** It's better to ask for help than to expose credentials.