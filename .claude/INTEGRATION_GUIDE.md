# Multi-Platform Integration Architecture

This document describes the architecture for integrating multiple external platforms (GitHub, Jira, Confluence) with the multi-agent workflow system using specialized integration coordinator agents.

## Architecture Overview

```
Internal Workflow (Queue System)
        |
        v
    Integration Hook (on-subagent-stop.sh)
        |
        +----> Determines which platforms to integrate
        |
        v
    Creates Integration Tasks
        |
        +----> GitHub Integration Task
        |      (github-integration-coordinator agent)
        |      - Creates issues
        |      - Creates PRs
        |      - Manages labels
        |
        +----> Atlassian Integration Task
               (atlassian-integration-coordinator agent)
               - Creates Jira tickets
               - Publishes to Confluence
               - Updates ticket status
```

## Specialized Integration Agents

### 1. GitHub Integration Coordinator

**Agent**: `github-integration-coordinator`
**MCP Server**: `github-mcp`
**File**: `.claude/agents/github-integration-coordinator.md`

**Responsibilities**:
- Create and manage GitHub issues
- Create and manage pull requests
- Apply and update labels
- Post comments with status updates
- Link issues to PRs

**When Used**:
- Every workflow status transition (if GitHub configured)
- Can be used independently of other integrations

**Configuration**: `.claude/mcp-servers/github-config.json`

### 2. Atlassian Integration Coordinator

**Agent**: `atlassian-integration-coordinator`
**MCP Server**: `atlassian-mcp`
**File**: `.claude/agents/atlassian-integration-coordinator.md`

**Responsibilities**:
- Create and manage Jira tickets
- Transition tickets through workflow
- Publish documentation to Confluence
- Update custom fields
- Cross-link with GitHub

**When Used**:
- Every workflow status transition (if Jira/Confluence configured)
- Can be used independently of other integrations

**Configuration**: `.claude/mcp-servers/atlassian-config.json`

## Integration Modes

### Mode 1: GitHub Only

**Use Case**: Open source projects, GitHub-centric teams

**Configuration**:
```bash
# Enable GitHub integration only
export ENABLE_GITHUB_INTEGRATION="true"
export ENABLE_ATLASSIAN_INTEGRATION="false"

# Set auto-integration mode
export AUTO_INTEGRATE="prompt"  # or "always" or "never"
```

**Behavior**:
- Only GitHub integration tasks created
- Issues and PRs created automatically
- No Jira tickets or Confluence pages

### Mode 2: Atlassian Only

**Use Case**: Teams using only Jira/Confluence

**Configuration**:
```bash
# Enable Atlassian integration only
export ENABLE_GITHUB_INTEGRATION="false"
export ENABLE_ATLASSIAN_INTEGRATION="true"

export AUTO_INTEGRATE="prompt"
```

**Behavior**:
- Only Jira/Confluence integration tasks created
- Tickets and documentation pages created
- No GitHub issues or PRs

### Mode 3: Both Platforms (Full Integration)

**Use Case**: Enterprise teams using both platforms

**Configuration**:
```bash
# Enable both integrations
export ENABLE_GITHUB_INTEGRATION="true"
export ENABLE_ATLASSIAN_INTEGRATION="true"

export AUTO_INTEGRATE="prompt"
```

**Behavior**:
- Both GitHub and Atlassian integration tasks created
- Cross-references maintained between platforms
- GitHub issues link to Jira tickets
- Jira tickets link to GitHub issues/PRs
- Confluence pages link to both

### Mode 4: Manual Only (No Auto-Integration)

**Use Case**: Full control, selective integration

**Configuration**:
```bash
# Disable auto-integration
export AUTO_INTEGRATE="never"

# Platforms still available for manual sync
export ENABLE_GITHUB_INTEGRATION="true"
export ENABLE_ATLASSIAN_INTEGRATION="true"
```

**Behavior**:
- No automatic integration tasks created
- Use manual commands:
  - `queue_manager.sh sync-github <task_id>`
  - `queue_manager.sh sync-atlassian <task_id>`
  - `queue_manager.sh sync-external <task_id>` (syncs all enabled)

## Configuration Files

### GitHub Configuration

**File**: `.claude/mcp-servers/github-config.json`

```json
{
  "github-mcp-config.json": {
    "mcpServers": {
      "github": {
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-github"],
        "env": {
          "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
        },
        "settings": {
          "default_owner": "your-username",
          "default_repo": "your-repo",
          "enabled": true
        }
      }
    }
  }
}
```

### Atlassian Configuration

**File**: `.claude/mcp-servers/atlassian-config.json`

```json
{
  "atlassian-mcp-config.json": {
    "mcpServers": {
      "atlassian": {
        "command": "npx",
        "args": ["-y", "mcp-server-atlassian"],
        "env": {
          "JIRA_EMAIL": "${JIRA_EMAIL}",
          "JIRA_API_TOKEN": "${JIRA_API_TOKEN}",
          "JIRA_URL": "https://company.atlassian.net"
        },
        "settings": {
          "enabled": true,
          "default_project": "PROJ"
        }
      }
    }
  }
}
```

## Queue Manager Integration

### New Commands

```bash
# Sync to specific platform
.claude/queues/queue_manager.sh sync-github <task_id>
.claude/queues/queue_manager.sh sync-atlassian <task_id>

# Sync to all enabled platforms
.claude/queues/queue_manager.sh sync-external <task_id>

# Sync all unsynced tasks to all platforms
.claude/queues/queue_manager.sh sync-all
```

### Updated add-integration Function

The queue manager now supports platform-specific integration:

```bash
# GitHub integration only
.claude/queues/queue_manager.sh add-integration \
  "READY_FOR_DEVELOPMENT" \
  "enhancements/feature/requirements-analyst/analysis_summary.md" \
  "requirements-analyst" \
  "parent_task_id" \
  --platform github

# Atlassian integration only
.claude/queues/queue_manager.sh add-integration \
  "READY_FOR_DEVELOPMENT" \
  "enhancements/feature/requirements-analyst/analysis_summary.md" \
  "requirements-analyst" \
  "parent_task_id" \
  --platform atlassian

# Both platforms (default if both enabled)
.claude/queues/queue_manager.sh add-integration \
  "READY_FOR_DEVELOPMENT" \
  "enhancements/feature/requirements-analyst/analysis_summary.md" \
  "requirements-analyst" \
  "parent_task_id"
```

## Hook Behavior

### Updated on-subagent-stop.sh

The hook now:
1. Detects workflow status
2. Checks which platforms are enabled
3. Creates appropriate integration tasks
4. Prompts user (if AUTO_INTEGRATE=prompt)

**Logic**:
```bash
# Check enabled platforms
if [ "$ENABLE_GITHUB_INTEGRATION" = "true" ]; then
    # Create GitHub integration task
fi

if [ "$ENABLE_ATLASSIAN_INTEGRATION" = "true" ]; then
    # Create Atlassian integration task
fi
```

## Workflow Status → Platform Actions

| Status | GitHub Action | Jira Action | Confluence Action |
|--------|--------------|-------------|-------------------|
| READY_FOR_DEVELOPMENT | Create issue | Create ticket | - |
| READY_FOR_IMPLEMENTATION | Update issue, add label | Transition to "In Progress" | Publish architecture doc |
| READY_FOR_TESTING | Create PR | Transition to "In Review" | - |
| TESTING_COMPLETE | Add PR comment, labels | Transition to "Testing" | - |
| DOCUMENTATION_COMPLETE | Close issue, merge PR | Transition to "Done" | Publish user guide |

## Cross-Platform Linking

### Link Hierarchy

```
Internal Task (task_1234567890_12345)
    |
    +----> GitHub Issue (#145)
    |      https://github.com/owner/repo/issues/145
    |      - Links to: Jira ticket, internal task
    |      - Metadata: jira_ticket, internal_task_id
    |
    +----> Jira Ticket (PROJ-456)
    |      https://company.atlassian.net/browse/PROJ-456
    |      - Links to: GitHub issue, internal task
    |      - Metadata: github_issue, internal_task_id
    |
    +----> GitHub PR (#156)
    |      https://github.com/owner/repo/pull/156
    |      - Links to: Issue #145, Jira PROJ-456
    |      - Closes: #145
    |
    +----> Confluence Pages
           Architecture: https://company.atlassian.net/wiki/.../arch
           User Guide: https://company.atlassian.net/wiki/.../guide
           - Link to: Jira ticket, GitHub issue/PR
```

### Metadata Storage

Each task stores all external references:

```json
{
  "metadata": {
    "github_issue": "145",
    "github_issue_url": "https://github.com/owner/repo/issues/145",
    "github_pr": "156",
    "github_pr_url": "https://github.com/owner/repo/pull/156",
    "jira_ticket": "PROJ-456",
    "jira_ticket_url": "https://company.atlassian.net/browse/PROJ-456",
    "confluence_architecture": "123456789",
    "confluence_architecture_url": "https://company.atlassian.net/wiki/.../arch",
    "confluence_userguide": "987654321",
    "confluence_userguide_url": "https://company.atlassian.net/wiki/.../guide"
  }
}
```

## Adding New Integration Platforms

To add a new platform (e.g., Slack, Linear, Azure DevOps):

### Step 1: Create Agent

Create `.claude/agents/{platform}-integration-coordinator.md`:

```markdown
---
name: {platform}-integration-coordinator
description: Manages {Platform} integration - ...
model: sonnet
tools: {platform}-mcp
---

# {Platform} Integration Coordinator

[Agent definition following the same pattern]
```

### Step 2: Add MCP Configuration

Create `.claude/mcp-servers/{platform}-config.json`:

```json
{
  "{platform}-mcp-config.json": {
    "mcpServers": {
      "{platform}": {
        "command": "npx",
        "args": ["-y", "mcp-server-{platform}"],
        "env": {
          "{PLATFORM}_TOKEN": "${PLATFORM_TOKEN}"
        },
        "settings": {
          "enabled": true
        }
      }
    }
  }
}
```

### Step 3: Update Agents Registry

Add to `.claude/agents/agents.json`:

```json
{
  "name": "{Platform} Integration Coordinator",
  "description": "Manages {Platform} integration...",
  "tools": ["Read", "Write", "Bash", "{platform}-mcp"]
}
```

### Step 4: Update Queue Manager

Add platform-specific sync command:

```bash
"sync-{platform}")
    # Platform-specific sync logic
    sync_{platform}_task "$2"
    ;;
```

### Step 5: Update Hook

Add platform detection in `on-subagent-stop.sh`:

```bash
if [ "$ENABLE_{PLATFORM}_INTEGRATION" = "true" ]; then
    add_integration_task "..." "..." "..." "..." "--platform {platform}"
fi
```

## Best Practices

### 1. Enable Only What You Need

Don't enable integrations you don't use:
```bash
# If you only use GitHub, disable Atlassian
export ENABLE_GITHUB_INTEGRATION="true"
export ENABLE_ATLASSIAN_INTEGRATION="false"
```

### 2. Start with Prompt Mode

Begin with manual approval:
```bash
export AUTO_INTEGRATE="prompt"
```

Upgrade to automatic after confidence builds:
```bash
export AUTO_INTEGRATE="always"
```

### 3. Cross-Link Everything

Ensure every platform references others:
- GitHub issues mention Jira tickets
- Jira tickets link to GitHub issues/PRs
- Confluence pages link to both

### 4. Use Metadata Extensively

Store all external IDs for idempotent operations:
```bash
queue_manager.sh update-metadata $TASK_ID github_issue "145"
queue_manager.sh update-metadata $TASK_ID jira_ticket "PROJ-456"
```

### 5. Test in Isolation

Test each platform independently before enabling both:
```bash
# Test GitHub only first
export ENABLE_GITHUB_INTEGRATION="true"
export ENABLE_ATLASSIAN_INTEGRATION="false"
# ... test ...

# Then test Atlassian only
export ENABLE_GITHUB_INTEGRATION="false"
export ENABLE_ATLASSIAN_INTEGRATION="true"
# ... test ...

# Finally enable both
export ENABLE_GITHUB_INTEGRATION="true"
export ENABLE_ATLASSIAN_INTEGRATION="true"
```

## Migration from Single Integration Agent

If you have the old `integration-coordinator` agent:

### Step 1: Update Agents

Replace:
- `.claude/agents/integration-coordinator.md`

With:
- `.claude/agents/github-integration-coordinator.md`
- `.claude/agents/atlassian-integration-coordinator.md`

### Step 2: Update agents.json

Replace the single integration entry with two entries.

### Step 3: Update Existing Tasks

Existing integration tasks with `integration-coordinator` will still work, but new tasks will use platform-specific agents.

### Step 4: Optional: Migrate Old Tasks

Update old task metadata to use new agent names:
```bash
jq '.pending_tasks[] | select(.assigned_agent == "integration-coordinator") | 
    .assigned_agent = "github-integration-coordinator"' \
    .claude/queues/task_queue.json
```

## Troubleshooting

### Both Platforms Enabled But Only One Working

**Check**:
1. Verify both MCP servers configured
2. Check environment variables set for both
3. Review logs for specific platform errors

### Integration Tasks Created But Not Running

**Check**:
1. Agent names match exactly in agents.json
2. MCP server names match tool names in agent frontmatter
3. Configuration files in correct location

### Cross-References Missing

**Check**:
1. Metadata being stored correctly
2. Both platform tasks completing successfully
3. Task IDs being passed correctly

## Summary

The specialized integration agent architecture provides:

✅ **Separation of Concerns**: Each platform has its own agent
✅ **Independent Evolution**: Platforms can change without affecting others
✅ **Team Collaboration**: Different team members can work on different integrations
✅ **Flexible Configuration**: Enable only what you need
✅ **Extensibility**: Easy to add new platforms

The system maintains full cross-platform consistency while allowing each integration to evolve independently.