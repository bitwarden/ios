# MCP Configuration Guide

This guide helps you set up Model Context Protocol (MCP) servers for integrating the multi-agent system with external platforms like GitHub, Jira, and Confluence.

## Table of Contents

- [Overview](#overview)
- [GitHub MCP Server Setup](#github-mcp-server-setup)
- [Atlassian MCP Server Setup](#atlassian-mcp-server-setup)
- [Claude Code Configuration](#claude-code-configuration)
- [Testing Integration](#testing-integration)
- [Troubleshooting](#troubleshooting)
- [Advanced Configuration](#advanced-configuration)
- [Security Best Practices](#security-best-practices)

## Overview

The integration system uses MCP servers to connect your multi-agent workflow with external systems:

- **GitHub MCP Server**: Creates issues, PRs, manages labels
- **Atlassian MCP Server**: Manages Jira tickets and Confluence documentation
- **Integration Coordinator Agent**: Orchestrates synchronization between systems

## GitHub MCP Server Setup

### Prerequisites

- Node.js 16+ installed
- GitHub Personal Access Token with repo permissions

### Installation

```bash
# Install the GitHub MCP server globally (optional)
npm install -g @modelcontextprotocol/server-github

# Or use npx (recommended - no installation needed)
# The config uses npx which will download on first use
```

### Configuration Steps

#### 1. Create a GitHub Personal Access Token

1. Go to GitHub Settings → Developer settings → Personal access tokens
2. Generate new token (classic)
3. Select scopes: `repo` (full control of private repositories)
4. Copy the token immediately (you won't see it again)

#### 2. Set Environment Variable

```bash
# Set the token for current session
export GITHUB_TOKEN="ghp_your_token_here"

# Add to your shell config for persistence
echo 'export GITHUB_TOKEN="ghp_your_token_here"' >> ~/.bashrc  # Bash
echo 'export GITHUB_TOKEN="ghp_your_token_here"' >> ~/.zshrc  # Zsh

# Reload shell config
source ~/.bashrc  # or source ~/.zshrc
```

#### 3. Update github-mcp-config.json

Edit `.claude/mcp-servers/github-mcp-config.json`:

```json
{
  "name": "github",
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-github"],
  "env": {
    "GITHUB_TOKEN": "${GITHUB_TOKEN}",
    "GITHUB_REPO": "owner/repo-name"
  },
  "config": {
    "default_owner": "your-github-username",
    "default_repo": "your-repo-name",
    "label_mapping": {
      "READY_FOR_DEVELOPMENT": ["enhancement", "ready-for-dev"],
      "READY_FOR_IMPLEMENTATION": ["architecture-complete"],
      "READY_FOR_TESTING": ["ready-for-review"],
      "TESTING_COMPLETE": ["tests-passing"],
      "DOCUMENTATION_COMPLETE": ["documented"]
    }
  }
}
```

#### 4. Copy Config to Claude Code

```bash
cp .claude/mcp-servers/github-mcp-config.json ~/.config/claude/mcp-servers/
```

## Atlassian MCP Server Setup

### Prerequisites

- Jira Cloud account
- Confluence Cloud account (optional, for documentation)
- Atlassian API token

### Current Status

**Note**: As of January 2025, there isn't an official Atlassian MCP server from Anthropic. You have several options:

#### Option A: Wait for Official Server

- Check [MCP Servers Repository](https://github.com/modelcontextprotocol/servers) for updates
- Monitor Anthropic's announcements
- Use GitHub integration only in the meantime

#### Option B: Use Community Implementation

```bash
# Clone a community Atlassian MCP server (when available)
git clone https://github.com/community/mcp-server-atlassian
cd mcp-server-atlassian
npm install
npm link
```

#### Option C: Build Your Own

Use the [MCP TypeScript SDK](https://github.com/modelcontextprotocol/typescript-sdk):

1. Implement Jira REST API calls
2. Implement Confluence REST API calls
3. Package as an MCP server

### Configuration Steps (When Available)

#### 1. Create Atlassian API Token

1. Go to [Atlassian Account Security](https://id.atlassian.com/manage-profile/security/api-tokens)
2. Create API token
3. Give it a descriptive name (e.g., "Claude Multi-Agent Integration")
4. Copy the token

#### 2. Set Environment Variables

```bash
# Set credentials for current session
export JIRA_EMAIL="your-email@company.com"
export JIRA_API_TOKEN="your_api_token_here"

# Add to shell config
echo 'export JIRA_EMAIL="your-email@company.com"' >> ~/.bashrc
echo 'export JIRA_API_TOKEN="your_token"' >> ~/.bashrc

# Reload shell config
source ~/.bashrc
```

#### 3. Update atlassian-mcp-config.json

Edit `.claude/mcp-servers/atlassian-mcp-config.json`:

```json
{
  "name": "atlassian",
  "command": "npx",
  "args": ["-y", "mcp-server-atlassian"],
  "env": {
    "JIRA_EMAIL": "${JIRA_EMAIL}",
    "JIRA_API_TOKEN": "${JIRA_API_TOKEN}",
    "JIRA_URL": "https://your-company.atlassian.net",
    "CONFLUENCE_URL": "https://your-company.atlassian.net/wiki"
  },
  "config": {
    "default_project": "PROJ",
    "CONFLUENCE_SPACE": "TEAM",
    "default_parent_page": "123456789",
    "status_mapping": {
      "READY_FOR_DEVELOPMENT": "To Do",
      "READY_FOR_IMPLEMENTATION": "In Progress",
      "READY_FOR_TESTING": "In Review",
      "TESTING_COMPLETE": "Testing",
      "DOCUMENTATION_COMPLETE": "Done"
    }
  }
}
```

#### 4. Copy Config to Claude Code

```bash
cp .claude/mcp-servers/atlassian-mcp-config.json ~/.config/claude/mcp-servers/
```

## Claude Code Configuration

### Add MCP Servers to Settings

Edit your Claude Code configuration file:

```bash
# Open Claude Code config
vim ~/.config/claude/config.json
```

Add the MCP servers:

```json
{
  "mcpServers": [
    "github-mcp-config.json",
    "atlassian-mcp-config.json"
  ]
}
```

### Verify Configuration

```bash
# Check that config files exist
ls -la ~/.config/claude/mcp-servers/

# Should see:
# github-mcp-config.json
# atlassian-mcp-config.json (if configured)
```

## Testing Integration

### Test GitHub Integration

```bash
# Test creating a GitHub issue
claude --agent integration-coordinator \
  --file enhancements/test-feature/requirements-analyst/analysis_summary.md \
  "Create a GitHub issue for this feature"
```

### Test Queue System Integration

```bash
# Enable auto-integration (always create integration tasks)
export AUTO_INTEGRATE="always"

# Add a task that will auto-integrate
.claude/queues/queue_manager.sh add \
  "Test feature requirements" \
  "requirements-analyst" \
  "high" \
  "analysis" \
  "enhancements/test/test.md" \
  "Analyze requirements and test integration"

# Start the task
.claude/queues/queue_manager.sh start <task_id>
```

### Integration Modes

Control integration behavior with the `AUTO_INTEGRATE` environment variable:

```bash
# Always create integration tasks automatically
export AUTO_INTEGRATE="always"

# Never create integration tasks (manual only)
export AUTO_INTEGRATE="never"

# Prompt before creating integration tasks (default)
export AUTO_INTEGRATE="prompt"
```

### Manual Integration

```bash
# Sync a specific completed task
.claude/queues/queue_manager.sh sync-external <task_id>

# Sync all unsynced completed tasks
.claude/queues/queue_manager.sh sync-all
```

## Troubleshooting

### GitHub Issues

#### Authentication Failed

**Problem**: Error message about authentication or invalid token

**Solutions**:
- Verify `GITHUB_TOKEN` is set: `echo $GITHUB_TOKEN`
- Check token has `repo` scope in GitHub settings
- Try regenerating the token
- Ensure token hasn't expired

#### Repository Not Found

**Problem**: Cannot find or access repository

**Solutions**:
- Verify `default_owner` and `default_repo` in config file
- Check repository name is correct (case-sensitive)
- Ensure you have access to the repository
- If private repo, confirm token has appropriate permissions

#### Rate Limit Exceeded

**Problem**: GitHub API rate limit reached

**Solutions**:
- Wait for rate limit to reset (check response headers)
- Use authenticated requests (should have 5000/hour limit)
- Consider spreading operations over time

### Jira/Confluence Issues

#### Invalid Credentials

**Problem**: Authentication fails for Atlassian services

**Solutions**:
- Check `JIRA_EMAIL` matches your Atlassian account email
- Verify `JIRA_API_TOKEN` is set correctly
- Try regenerating the API token
- Ensure email and token match the same account

#### Project Not Found

**Problem**: Jira project cannot be accessed

**Solutions**:
- Verify project key is correct (case-sensitive, usually uppercase)
- Ensure you have access to the project in Jira
- Check project hasn't been archived or deleted
- Confirm you're using the right Jira instance URL

#### Confluence Page Parent Not Found

**Problem**: Cannot create pages under specified parent

**Solutions**:
- Get correct parent page ID from Confluence URL
- Verify you have edit permissions for the space
- Check parent page hasn't been deleted
- Ensure space key is correct

### MCP Server Issues

#### MCP Server Not Found

**Problem**: Cannot locate or execute MCP server

**Solutions**:
- Verify Node.js is installed: `node --version` (need 16+)
- Try installing the server globally: `npm install -g @modelcontextprotocol/server-github`
- Check npx is working: `npx --version`
- Ensure PATH includes npm global bin directory

#### Connection Timeout

**Problem**: MCP server connection times out

**Solutions**:
- Check internet connection
- Verify firewall isn't blocking npm/npx
- Try running MCP server command directly to see errors
- Check corporate proxy settings if behind firewall

#### Command Execution Fails

**Problem**: MCP server command fails to execute

**Solutions**:
- Run command manually to see full error output
- Check file permissions on config files
- Verify JSON syntax in config files
- Look for typos in command or args in config

## Advanced Configuration

### Custom Label Mappings

Customize how workflow statuses map to GitHub labels in `github-mcp-config.json`:

```json
{
  "config": {
    "label_mapping": {
      "READY_FOR_DEVELOPMENT": ["enhancement", "ready-for-dev", "sprint-ready"],
      "READY_FOR_IMPLEMENTATION": ["architecture-complete", "approved"],
      "READY_FOR_TESTING": ["ready-for-review", "needs-testing"],
      "TESTING_COMPLETE": ["tests-passing", "qa-approved"],
      "DOCUMENTATION_COMPLETE": ["documented", "ready-to-merge"],
      "CUSTOM_STATUS": ["custom-label-1", "custom-label-2"]
    }
  }
}
```

### Custom Jira Workflows

Map internal statuses to your Jira workflow in `atlassian-mcp-config.json`:

```json
{
  "config": {
    "status_mapping": {
      "READY_FOR_DEVELOPMENT": "Backlog",
      "READY_FOR_IMPLEMENTATION": "In Progress",
      "READY_FOR_TESTING": "Code Review",
      "TESTING_COMPLETE": "QA Testing",
      "DOCUMENTATION_COMPLETE": "Done",
      "BLOCKED": "Blocked"
    }
  }
}
```

### Issue and PR Templates

Customize GitHub issue and PR templates in your integration agent prompts or create template files:

**Issue Template**:
```markdown
## Description
[Brief description]

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Technical Notes
[Any technical considerations]

## Related
- Jira: [PROJ-123](url)
- Documentation: [link]
```

**PR Template**:
```markdown
## Summary
[Implementation summary]

## Changes
- Change 1
- Change 2

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing complete

## Related Issues
Closes #123
Related: PROJ-456
```

### Webhook Integration (Future Enhancement)

For bidirectional synchronization, you can set up webhooks:

#### GitHub Webhooks
- Receive events when issues/PRs are updated externally
- Update internal queue status automatically
- Requires webhook handler service

#### Jira Webhooks
- Sync status changes back to internal queue
- Update when tickets are moved or modified
- Requires webhook receiver endpoint

**Implementation requires**:
- Web server to receive webhooks
- Webhook signature verification
- Queue manager API for updates

## Security Best Practices

### Token Management

1. **Never commit tokens to git**
   - Add `.env` files to `.gitignore`
   - Use environment variables exclusively
   - Review commits before pushing

2. **Use minimal permissions**
   - GitHub: Only `repo` scope needed (or `public_repo` for public repos)
   - Jira: Only grant project-specific access
   - Confluence: Only required space permissions

3. **Rotate tokens regularly**
   - Set calendar reminders for quarterly rotation
   - Regenerate immediately if token is exposed
   - Keep audit log of token creation/rotation

4. **Use service accounts for teams**
   - Create dedicated service account for automation
   - Avoid using personal tokens for shared projects
   - Ensure multiple team members can access/rotate tokens

### Configuration Security

1. **Protect config files**
   ```bash
   chmod 600 ~/.config/claude/mcp-servers/*.json
   ```

2. **Use environment variables**
   - Never hardcode tokens in config files
   - Use `${ENV_VAR}` syntax in JSON configs
   - Verify vars are set: `env | grep GITHUB`

3. **Review permissions**
   - Audit what repos/projects tokens can access
   - Remove access to unused repos/projects
   - Use repository-scoped tokens when possible

### Audit and Monitoring

1. **Review API activity**
   - Check GitHub API usage in settings
   - Monitor Jira audit logs
   - Watch for unexpected activity

2. **Log integration operations**
   - Queue manager logs all operations
   - Review logs regularly: `.claude/logs/queue_operations.log`
   - Check for failed operations or errors

3. **Test in non-production first**
   - Use test repository for initial setup
   - Create test Jira project
   - Verify operations before using in production

## References

- [Model Context Protocol Documentation](https://modelcontextprotocol.io)
- [MCP Servers Repository](https://github.com/modelcontextprotocol/servers)
- [GitHub MCP Server](https://github.com/modelcontextprotocol/servers/tree/main/src/github)
- [Claude Code Documentation](https://docs.claude.com/claude-code)
- [GitHub REST API](https://docs.github.com/en/rest)
- [Jira REST API](https://developer.atlassian.com/cloud/jira/platform/rest/v3/)
- [Confluence REST API](https://developer.atlassian.com/cloud/confluence/rest/v1/)
- [GitHub Personal Access Tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
- [Atlassian API Tokens](https://support.atlassian.com/atlassian-account/docs/manage-api-tokens-for-your-atlassian-account/)

## Getting Help

If you encounter issues not covered in this guide:

1. Check the queue operation logs: `.claude/logs/queue_operations.log`
2. Check agent execution logs: `enhancements/*/logs/`
3. Review MCP server documentation
4. Check GitHub/Jira API status pages
5. File an issue in the project repository

## Next Steps

After setting up MCP servers:

1. Test with a simple enhancement
2. Verify GitHub issue creation
3. Test PR creation workflow
4. Enable auto-integration if desired
5. Customize labels and workflows for your team
6. Document your team's integration workflow