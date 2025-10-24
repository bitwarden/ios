# 6502 Kernel Queue System Guide

## Overview

The queue system provides comprehensive task management, workflow orchestration, and agent communication tracking for the 6502 Kernel multi-agent development environment.

## Architecture

```
.claude/
├── queues/
│   ├── task_queue.json          # Main task queue and agent status
│   ├── queue_manager.sh         # Queue management script
│   └── workflow_templates.json  # Predefined workflow templates
├── logs/
│   └── queue_operations.log     # Queue operation history
└── status/
    └── workflow_state.json      # Current workflow state and milestones

enhancements/
└── {enhancement-name}/
    └── logs/                    # Enhancement-specific agent logs
        └── {agent}_{task_id}_{timestamp}.log
```

## Queue Manager Usage

### Basic Operations

```bash
# Check queue status
.claude/queues/queue_manager.sh status

# Add a task
.claude/queues/queue_manager.sh add \
  "Task title" \
  "agent-name" \
  "priority" \
  "task_type" \
  "source_file" \
  "Description"

# Start a specific task
.claude/queues/queue_manager.sh start task_id

# Complete a task (basic)
.claude/queues/queue_manager.sh complete task_id "completion_message"

# Complete a task with auto-chain (NEW)
.claude/queues/queue_manager.sh complete task_id "READY_FOR_DEVELOPMENT - Requirements complete" --auto-chain

# Cancel a task (NEW)
.claude/queues/queue_manager.sh cancel task_id "cancellation_reason"

# Fail a task
.claude/queues/queue_manager.sh fail task_id "error_message"
```

### Auto-Chain Functionality (Smart Workflow)

The queue system now includes intelligent auto-chaining that can automatically suggest and create follow-up tasks based on completion status:

```bash
# Complete with auto-chain - system analyzes status and suggests next task
.claude/queues/queue_manager.sh complete task_123 "READY_FOR_DEVELOPMENT - Requirements analysis complete" --auto-chain

# System responds with:
# AUTO-CHAIN SUGGESTION:
#   Title: Architecture design for enhancement-name
#   Agent: assembly-developer  (auto-detected from enhancement content)
#   Description: Design architecture and system structure for enhancement-name enhancement
#
# Create this task? [y/N]: y
# ✅ Created task: task_456
```

### Smart Agent Assignment

The system automatically determines the best agent for next phase tasks by analyzing:

**Content Analysis:**
- **6502/Assembly keywords** → `assembly-developer`
- **C++/Simulator keywords** → `cpp-developer`
- **Mixed or unclear** → Interactive choice prompt

**Status-Based Assignment:**
- `READY_FOR_DEVELOPMENT` → Architecture agent (cpp-developer or assembly-developer)
- `READY_FOR_IMPLEMENTATION` → Implementation agent (usually same as architecture)
- `READY_FOR_INTEGRATION/TESTING` → `testing-agent`

### Workflow Management

```bash
# Start a predefined workflow
.claude/queues/queue_manager.sh workflow sequential_development "Implement new feature"
.claude/queues/queue_manager.sh workflow parallel_development "Parallel implementation"
.claude/queues/queue_manager.sh workflow hotfix_flow "Critical bug fix"
```

### Available Workflows

1. **sequential_development**: Requirements → C++ → Assembly → Testing
2. **parallel_development**: Requirements → (C++ + Assembly) → Testing
3. **hotfix_flow**: Assembly → Testing (for critical fixes)

## Task Priorities

- **critical**: Emergency fixes, blocking issues
- **high**: Important features, significant bugs
- **normal**: Regular development tasks
- **low**: Nice-to-have improvements

## Agent Status States

- **idle**: Ready for new tasks
- **active**: Currently working on a task
- **blocked**: Waiting for dependencies
- **error**: Encountered issues

## Workflow Templates

### New Feature Development Template

1. **Requirements Analysis** (1-2 hours)
   - Feature specification
   - Implementation plan
   - Technical constraints

2. **Parallel Development** (3-6 hours)
   - C++ components and tools
   - 6502 assembly implementation

3. **Comprehensive Testing** (2-3 hours)
   - Unit and integration tests
   - Hardware validation

### Bug Fix Template

1. **Bug Analysis** (30 minutes)
2. **Targeted Fix** (varies by component)
3. **Validation Testing** (1 hour)

## Integration with Hooks

The queue system automatically integrates with Claude Code hooks:

### SubagentStop Hook Integration
- Automatically completes tasks when agents finish
- Queues follow-up tasks based on completion status
- Updates workflow state and milestones

### Stop Hook Integration
- Provides queue status after any operation
- Suggests next actions based on current state
- Shows available agents and pending work

## Human-in-the-Loop (HITL) Workflow Design

The system implements a **Human-in-the-Loop** approach that balances automation with human oversight for quality control and validation.

### What's Automated:
- ✅ **Status Detection**: Hooks automatically detect agent completion status
- ✅ **Task Completion**: Queue system marks tasks complete based on status output
- ✅ **Follow-up Queuing**: Next phase tasks are automatically queued
- ✅ **Workflow Suggestions**: System provides intelligent next step recommendations

### What Stays Manual (HITL):
- 🔍 **Human Validation**: Review and validate completed work quality
- 🔍 **Proceed Decision**: Human decides whether to advance to next phase
- 🔍 **Agent Selection**: Choose appropriate agent for next tasks
- 🔍 **Context Review**: Verify handoff information and requirements

### Typical HITL Flow:
```bash
1. Agent completes work → Outputs status (e.g., "READY_FOR_TESTING")
2. Hook detects status → Automatically queues testing tasks
3. 👤 HUMAN REVIEWS: Validate implementation quality and completeness
4. 👤 HUMAN DECIDES: "Proceed to testing phase" or "Needs revision"
5. 👤 HUMAN STARTS: .claude/queues/queue_manager.sh start testing-agent
```

### Benefits of HITL Approach:
- **Quality Control**: Human validates each phase before proceeding
- **Flexibility**: Can adjust course based on intermediate results
- **Learning**: Builds understanding of agent capabilities over time
- **Safety**: Prevents cascading errors from one phase to the next
- **Gradual Automation**: Can selectively automate transitions as confidence grows

### Future Migration Path:
As the system matures, specific transitions can be selectively automated:
- **Low-risk transitions** → Full automation
- **Critical phases** → Maintain HITL validation
- **Known patterns** → Conditional automation
- **Emergency workflows** → Override capabilities

### HITL Validation Checklist:
Before proceeding to the next phase, verify:
- [ ] Agent completed all stated objectives
- [ ] Output quality meets project standards
- [ ] No obvious errors or omissions
- [ ] Context and handoff information is clear
- [ ] Next phase agent has sufficient information to proceed

## Workflow State Tracking

The system tracks:
- **Current Workflow**: Active workflow and progress
- **Agent Activity**: Task completion and status via logs
- **Project Milestones**: Key completion markers
- **Blockers**: Issues preventing progress
- **Recommended Actions**: Next steps suggestions

### Agent Logging

Each agent logs its work to enhancement-specific directories:
- **Location**: `enhancements/{enhancement-name}/logs/`
- **Format**: `{agent}_{task_id}_{timestamp}.log`
- **Content**: Detailed execution logs, decisions, and results

## Advanced Usage Examples

### Starting a New Feature

```bash
# Create enhancement file first
mkdir -p enhancements/add-monitor-command
echo "# Add D: Monitor Command" > enhancements/add-monitor-command/add-monitor-command.md

# Add initial requirements task
TASK_ID=$(.claude/queues/queue_manager.sh add \
  "Analyze new monitor command" \
  "requirements-analyst" \
  "high" \
  "analysis" \
  "enhancements/add-monitor-command/add-monitor-command.md" \
  "Add D: command for hex/ASCII display")

# Check status
.claude/queues/queue_manager.sh status

# The SubagentStop hook will automatically queue follow-up tasks
```

### Monitoring Progress

```bash
# View queue status
./.claude/queues/queue_manager.sh status

# Check agent logs for specific enhancement
tail -f enhancements/add-basic-interpreter/logs/*.log

# View workflow state
cat .claude/status/workflow_state.json | jq '.project_milestones'
```

### Managing Parallel Development

```bash
# Start parallel workflow
./.claude/queues/queue_manager.sh workflow parallel_development "Implement new feature X"

# Both cpp-developer and assembly-developer tasks will be queued
# Testing agent will be queued automatically when both complete
```

## Troubleshooting

### Common Issues

1. **Queue file corruption**: Restore from backup or reinitialize
2. **Permission errors**: Ensure scripts are executable (`chmod +x`)
3. **JSON parsing errors**: Validate JSON syntax with `jq`

### Debugging Commands

```bash
# Check queue file syntax
jq '.' .claude/queues/task_queue.json

# View recent queue operations
tail -f .claude/logs/queue_operations.log

# Check agent logs for specific enhancement
ls -lt enhancements/*/logs/*.log | head -10
tail -f enhancements/{enhancement-name}/logs/{agent}_*.log
```

### Recovery Procedures

```bash
# Reset queue to clean state
cp .claude/queues/task_queue.json .claude/queues/task_queue.json.backup
# Edit manually or restore from template

# Clean old enhancement logs (optional)
find enhancements/*/logs -name "*.log" -mtime +30 -delete
```

## Best Practices

### Task Management
- Use descriptive task titles
- Set appropriate priorities
- Include detailed descriptions
- Monitor queue regularly

### Workflow Organization
- Choose appropriate workflow templates
- Start with requirements analysis for new features
- Use parallel development for independent components
- Always end with comprehensive testing

### Agent Coordination
- Review agent logs in enhancement directories
- Track completion status in queue system
- Monitor for blockers via status updates
- Maintain clear task descriptions for handoffs

### Maintenance
- Clean logs regularly
- Monitor queue performance
- Update workflow templates as needed
- Review and optimize agent assignments

## Integration with Development Workflow

The queue system integrates seamlessly with:
- **Git workflow**: Tasks can trigger commits and PRs
- **Build system**: Testing tasks integrate with CMake/Ninja
- **CI/CD**: Queue status can drive automation
- **Documentation**: Completion triggers doc updates

## Performance Considerations

- Queue file size grows with usage (regular cleanup recommended)
- Agent logs accumulate in enhancement directories (periodic cleanup recommended)
- JSON operations scale well up to hundreds of tasks
- Hook execution adds minimal overhead

## Future Enhancements

Potential improvements:
- Web dashboard for queue visualization
- Slack/Discord integration for notifications
- Automatic task estimation and scheduling
- Machine learning for optimal agent assignment
- Integration with external project management tools