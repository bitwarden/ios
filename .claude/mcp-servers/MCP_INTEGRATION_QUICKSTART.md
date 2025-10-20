# GitHub/Jira Integration Quick Start

This guide gets you up and running with GitHub and Jira integration in 10 minutes.

## Prerequisites Checklist

- [ ] GitHub Personal Access Token created
- [ ] Jira API Token created (if using Jira)
- [ ] Node.js 16+ installed
- [ ] Repository and project identifiers ready

## Step 1: Set Up GitHub Token (5 minutes)

### Create Token

1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Name: "Claude Multi-Agent Integration"
4. Scopes: Select **`repo`** (Full control of private repositories)
5. Click "Generate token"
6. **Copy the token immediately** (you won't see it again!)

### Set Environment Variable

```bash
# Add to your shell config (~/.bashrc or ~/.zshrc)
echo 'export GITHUB_TOKEN="ghp_your_token_here"' >> ~/.bashrc

# Reload your shell
source ~/.bashrc

# Verify it's set
echo $GITHUB_TOKEN
```

## Step 2: Configure GitHub MCP Server (2 minutes)

Edit `.claude/mcp-servers/github-config.json`:

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
          "default_owner": "YOUR-GITHUB-USERNAME",
          "default_repo": "YOUR-REPO-NAME",
          "default_branch": "main"
        }
      }
    }
  }
}
```

**Replace**:
- `YOUR-GITHUB-USERNAME` with your GitHub username
- `YOUR-REPO-NAME` with your repository name

## Step 3: Test GitHub Integration (2 minutes)

### Test with Auto-Integration

```bash
# Enable automatic integration
export AUTO_INTEGRATE="always"

# Create a test enhancement
mkdir -p enhancements/test-integration
cat > enhancements/test-integration/test-integration.md << 'EOF'
# Test Integration Feature

## Description
Testing GitHub/Jira integration with the multi-agent system.

## Acceptance Criteria
- GitHub issue created automatically
- Issue has proper labels
- Issue links back to internal task

## Notes
This is a test to verify the integration system works.
EOF

# Add requirements analysis task
TASK_ID=$(.claude/queues/queue_manager.sh add \
  "Analyze test-integration enhancement" \
  "requirements-analyst" \
  "high" \
  "analysis" \
  "enhancements/test-integration/test-integration.md" \
  "Test requirements analysis with integration")

echo "Created task: $TASK_ID"

# Start the task
.claude/queues/queue_manager.sh start $TASK_ID
```

**What happens**:
1. Requirements analyst analyzes the test enhancement
2. Outputs `READY_FOR_DEVELOPMENT` status
3. Hook detects status and creates integration task automatically
4. Integration coordinator creates GitHub issue
5. Issue URL and ID stored in task metadata

### Check Results

```bash
# View queue status
.claude/queues/queue_manager.sh status

# Check for integration tasks
jq '.pending_tasks[] | select(.assigned_agent == "integration-coordinator")' .claude/queues/task_queue.json

# Check GitHub for the created issue
# Visit: https://github.com/YOUR-USERNAME/YOUR-REPO/issues
```

## Step 4: Manual Integration (Optional)

### Sync a Specific Task

```bash
# Get task ID from completed tasks
.claude/queues/queue_manager.sh status

# Sync specific task to GitHub/Jira
.claude/queues/queue_manager.sh sync-external <task_id>
```

### Sync All Unsynced Tasks

```bash
# Find all completed tasks that need integration
.claude/queues/queue_manager.sh sync-all
```

### Update Task Metadata

```bash
# Store external IDs manually if needed
.claude/queues/queue_manager.sh update-metadata <task_id> github_issue "145"
.claude/queues/queue_manager.sh update-metadata <task_id> github_issue_url "https://github.com/..."
```

## Integration Modes

Control integration behavior with the `AUTO_INTEGRATE` environment variable:

### Always Integrate (Fully Automated)

```bash
export AUTO_INTEGRATE="always"
# Integration tasks created automatically after each phase
# No prompts - fully automated
```

### Prompt Mode (Default - Recommended)

```bash
export AUTO_INTEGRATE="prompt"
# or just unset it
unset AUTO_INTEGRATE

# System asks: "Create integration task? [y/N]:"
# Gives you control while suggesting integration
```

### Never Integrate (Manual Only)

```bash
export AUTO_INTEGRATE="never"
# No automatic integration
# Use sync-external or sync-all commands manually
```

## Workflow Status → GitHub Actions

The integration system automatically handles these transitions:

| Workflow Status | GitHub Action | Jira Action |
|----------------|---------------|-------------|
| `READY_FOR_DEVELOPMENT` | Create issue with labels | Create ticket |
| `READY_FOR_IMPLEMENTATION` | Add "architecture-complete" label | Update status to "In Progress" |
| `READY_FOR_TESTING` | Create pull request | Update status to "In Review" |
| `TESTING_COMPLETE` | Add "tests-passing" label | Update status to "Testing" |
| `DOCUMENTATION_COMPLETE` | Close issue, merge PR | Update status to "Done" |

## Common Use Cases

### Start a New Feature with Full Integration

```bash
# 1. Create enhancement file
mkdir -p enhancements/add-search-feature
vim enhancements/add-search-feature/add-search-feature.md

# 2. Enable auto-integration
export AUTO_INTEGRATE="always"

# 3. Add initial requirements task
TASK_ID=$(.claude/queues/queue_manager.sh add \
  "Analyze search feature requirements" \
  "requirements-analyst" \
  "high" \
  "analysis" \
  "enhancements/add-search-feature/add-search-feature.md" \
  "Analyze requirements for search functionality")

# 4. Start the task
.claude/queues/queue_manager.sh start $TASK_ID

# Result: GitHub issue will be created automatically after requirements complete
```

### Continue Development with PR Creation

After implementation is complete:

```bash
# Implementation phase outputs READY_FOR_TESTING
# Integration task is automatically created
# Start the integration task to create PR

# Find the integration task
.claude/queues/queue_manager.sh status | grep integration-coordinator

# Start it
.claude/queues/queue_manager.sh start <integration_task_id>

# Result: Pull request created linking to original issue
```

### Check Integration Status

```bash
# View all integration tasks
jq '.pending_tasks[], .active_workflows[], .completed_tasks[] | 
    select(.assigned_agent == "integration-coordinator")' \
    .claude/queues/task_queue.json

# Check what's been synced
jq '.completed_tasks[] | 
    select(.metadata.github_issue != null) | 
    {id, title, github_issue, jira_ticket}' \
    .claude/queues/task_queue.json
```

## Troubleshooting

### "GitHub Token Not Set"

```bash
# Verify token is set
echo $GITHUB_TOKEN

# If empty, add to shell config
echo 'export GITHUB_TOKEN="ghp_your_token_here"' >> ~/.bashrc
source ~/.bashrc
```

### "Repository Not Found"

```bash
# Check your config has correct owner/repo
cat .claude/mcp-servers/github-config.json | jq '.["github-mcp-config.json"].mcpServers.github.settings'

# Update if needed
vim .claude/mcp-servers/github-config.json
```

### "Rate Limit Exceeded"

```bash
# Check your rate limit status
curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/rate_limit

# Wait for reset or space out operations
```

### Integration Task Fails

```bash
# Check the integration log
LATEST_LOG=$(ls -t enhancements/*/logs/integration-coordinator_* | head -1)
cat "$LATEST_LOG"

# Retry the integration
.claude/queues/queue_manager.sh sync-external <task_id>
```

## Advanced: Custom Label Mappings

Edit `.claude/mcp-servers/github-config.json` to customize labels:

```json
{
  "label_mapping": {
    "READY_FOR_DEVELOPMENT": ["ready-for-dev", "requirements-complete", "sprint-ready"],
    "READY_FOR_TESTING": ["needs-review", "ready-for-qa"],
    "TESTING_COMPLETE": ["qa-approved", "ready-to-ship"]
  }
}
```

## Next Steps

1. **Set up Jira** (optional): Follow MCP_CONFIGURATION_GUIDE.md for Jira setup
2. **Customize labels**: Edit github-config.json label mappings for your workflow
3. **Create templates**: Customize issue/PR templates in the config
4. **Enable in CI/CD**: Add AUTO_INTEGRATE to your CI environment

## Getting Help

- Review integration logs: `enhancements/*/logs/integration-coordinator_*.log`
- Check queue operations: `.claude/logs/queue_operations.log`
- Full documentation: `.claude/mcp-servers/MCP_CONFIGURATION_GUIDE.md`
- Test with sample enhancement first before using on real features

## Quick Reference

```bash
# Enable automatic integration
export AUTO_INTEGRATE="always"

# Check status
.claude/queues/queue_manager.sh status

# Sync specific task
.claude/queues/queue_manager.sh sync-external <task_id>

# Sync all unsynced
.claude/queues/queue_manager.sh sync-all

# Update metadata
.claude/queues/queue_manager.sh update-metadata <task_id> <key> <value>

# View integration tasks
jq '.[] | select(.assigned_agent == "integration-coordinator")' .claude/queues/task_queue.json
```

---

**You're ready to integrate!** Start with a test enhancement to verify everything works, then use it on real features.
