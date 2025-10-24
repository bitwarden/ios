# Claude Multi-Agent Development System

This directory contains a comprehensive multi-agent system for managing software development projects using Claude Code. The system implements specialized agents with automated workflow transitions through hooks.

## Architecture Overview

The multi-agent system follows the single-responsibility principle with five specialized agents:

1. **Requirements Analyst** - Requirements analysis and implementation planning
2. **Architect** - System architecture and technical design
3. **Implementer** - Production code implementation
4. **Tester** - Comprehensive testing and validation
5. **Documenter** - Documentation creation and maintenance

## Agent Specifications

### Requirements Analyst (`requirements-analyst.md`)
- **Purpose**: Analyzes requirements, creates implementation plans, manages project scope
- **Tools**: Read, Write, Glob, Grep, WebSearch, WebFetch
- **Outputs**: `READY_FOR_DEVELOPMENT` status
- **Use Case**: Start of new features or major project phases

### Architect (`architect.md`)
- **Purpose**: Designs system architecture, makes technical decisions
- **Tools**: Read, Write, Edit, MultiEdit, Bash, Glob, Grep, WebSearch, WebFetch
- **Outputs**: `READY_FOR_IMPLEMENTATION` status
- **Use Case**: Technical design and architecture decisions

### Implementer (`implementer.md`)
- **Purpose**: Implements features based on architectural specifications
- **Tools**: Read, Write, Edit, MultiEdit, Bash, Glob, Grep, Task
- **Outputs**: `READY_FOR_TESTING` or `IMPLEMENTATION_COMPLETE` status
- **Use Case**: Writing production code

### Tester (`tester.md`)
- **Purpose**: Designs and implements comprehensive test suites
- **Tools**: Read, Write, Edit, MultiEdit, Bash, Glob, Grep, Task
- **Outputs**: `TESTING_COMPLETE` status
- **Use Case**: Quality assurance and validation

### Documenter (`documenter.md`)
- **Purpose**: Creates and maintains project documentation
- **Tools**: Read, Write, Edit, MultiEdit, Bash, Glob, Grep
- **Outputs**: `DOCUMENTATION_COMPLETE` status
- **Use Case**: User guides, API docs, and technical documentation

## Workflow Patterns

### Standard Development Flow
```
Requirements Analyst → Architect → Implementer → Tester → Documenter
```

### Bug Fix Flow
```
Requirements Analyst → Architect → Implementer → Tester
```

### Hotfix Flow
```
Implementer → Tester
```

## Hook System

The project implements automated workflow transitions through two main hooks:

### SubagentStop Hook (`hooks/on-subagent-stop.sh`)
- Triggers when any subagent completes its task
- Analyzes agent output for status markers
- Suggests next steps based on completion status
- Manages workflow transitions between agents

### General Stop Hook (`hooks/on-stop.sh`)
- Triggers on any command or agent completion
- Provides project status assessment
- Suggests contextual next actions
- Lists available agents and their purposes

## Queue System

The system includes a sophisticated task queue for managing workflows:

### Queue Manager (`queues/queue_manager.sh`)
- Add, start, complete, and manage tasks
- Track agent status and availability
- Support for workflow templates
- Auto-chaining for sequential workflows

### Workflow Templates (`queues/workflow_templates.json`)
- Predefined workflows for common scenarios
- New feature development
- Bug fixes and hotfixes
- Performance optimization
- Documentation updates
- Code refactoring

See [QUEUE_SYSTEM_GUIDE.md](QUEUE_SYSTEM_GUIDE.md) for detailed documentation.

## Usage Instructions

### Starting a New Feature
1. Launch Requirements Analyst agent:
   ```
   Use Task tool with subagent_type: "requirements-analyst"
   ```
2. Follow hook suggestions for next steps
3. Launch appropriate agents based on requirements

### Development Phase
- **For architecture**: Use `architect` agent
- **For implementation**: Use `implementer` agent
- **For testing**: Use `tester` agent
- **For documentation**: Use `documenter` agent

### Status Tracking
The hook system provides automatic status tracking with these states:
- `READY_FOR_DEVELOPMENT` - Requirements complete, ready for architecture
- `READY_FOR_IMPLEMENTATION` - Architecture complete, ready to code
- `READY_FOR_TESTING` - Implementation complete, ready to test
- `TESTING_COMPLETE` - All testing passed
- `DOCUMENTATION_COMPLETE` - Documentation finished

## Agent Output Organization

Each agent writes its output files to its own subdirectory within the enhancement directory:

```
enhancements/
└── add-json-export/
    ├── add-json-export.md          # Initial enhancement spec
    ├── requirements-analyst/        # Requirements Analyst output
    │   ├── analysis_summary.md
    │   └── [additional analysis files]
    ├── architect/                   # Architect output
    │   ├── implementation_plan.md
    │   └── [additional design docs]
    ├── implementer/                 # Implementer output
    │   ├── test_plan.md
    │   └── [implementation notes]
    ├── tester/                      # Tester output
    │   ├── test_summary.md
    │   └── [test results]
    └── logs/                        # Agent execution logs
        └── [agent]_[task_id]_[timestamp].log
```

**Benefits:**
- Clear separation of agent outputs
- Easy to identify which agent created which files
- Cleaner enhancement directories
- Agent work is isolated and organized

## Agent Communication

Agents communicate through:
1. **Status Markers**: Standardized completion messages
2. **Hook System**: Automated workflow transitions
3. **Shared Documentation**: Common understanding of project structure
4. **File-based Handoffs**: Each agent reads from the previous agent's subdirectory

## Best Practices

### Agent Selection
- Use the **most specialized agent** for each task
- Follow **hook suggestions** for optimal workflow
- Consider task dependencies when sequencing work

### Task Handoffs
- Ensure **clear completion status** from each agent
- Review **agent output** before proceeding to next phase
- Use **hooks for guidance** on next steps

### Quality Assurance
- Always run **Tester Agent** before considering work complete
- Use **Documenter Agent** to maintain up-to-date documentation
- Follow **project-specific standards** documented in each agent spec

## Project-Specific Customization

### Bitwarden iOS Project Configuration

This is an iOS project implementing two main applications: **Password Manager** and **Authenticator**. All agents should be aware of the following project-specific requirements:

#### Project Type and Languages
- **Platform**: iOS 15.0+, watchOS 9.0+
- **Primary Language**: Swift 5.9+
- **Architecture**: SwiftUI + Coordinator-Processor Pattern
- **Build System**: Xcode 26+, XcodeGen for project generation

#### Key Technologies and Frameworks
- **UI Framework**: SwiftUI with custom components
- **Data Persistence**: CoreData, Keychain, UserDefaults
- **Networking**: Custom networking layer built on URLSession
- **Testing Frameworks**: XCTest, Swift Testing, ViewInspector, SnapshotTesting
- **Code Generation**: Sourcery (for mock generation)
- **Security**: Bitwarden SDK (encryption/decryption operations)
- **CI/CD**: GitHub Actions

#### Critical Project Rules

**NEVER**:
- Add third-party libraries without explicit approval
- Add new encryption logic to this repository (use Bitwarden SDK)
- Send unencrypted vault data to API services
- Commit secrets, credentials, or sensitive information
- Log decrypted data, encryption keys, or PII
- Create new top-level folders in `Core/` or `UI/` (use existing domains)
- Access Stores directly from UI layer (use Repositories)
- Mutate state directly in Views (only in Processors)
- Put business logic in Coordinators

**ALWAYS**:
- Follow the Coordinator → Processor → State → View flow for UI changes
- Use Repositories in the UI layer (never Stores or Services directly)
- Co-locate test files with implementation files
- Use Sourcery `AutoMockable` for protocol mocks
- Test in all required modes: light, dark, large dynamic type (for views)
- Use relative paths in documentation

#### Architecture Patterns

**Core Layer (Data)**:
- Models: Domain, Request, Response, Enum types
- Stores: CoreData, Keychain, UserDefaults persistence
- Services: Single-responsibility data operations
- Repositories: Multi-source data synthesis

**UI Layer (Presentation)**:
- Coordinators: Navigation and flow management
- Processors: State management and business logic
- State: Equatable view state models
- Views: SwiftUI views (no logic, only rendering)
- Store: Bridge between Processor and View

**Domain Organization**:
- Auth, Autofill, Platform, Tools, Vault
- No new domains without team approval

#### Coding Standards

See [Code Style Guide](https://contributing.bitwarden.com/contributing/code-style/swift/) for complete standards.

**Key Conventions**:
- Use `final` for classes that shouldn't be subclassed
- Protocol-based dependency injection via `Services` typealias
- SwiftLint enforced (configuration in `.swiftlint.yml`)
- SwiftFormat for consistent formatting

#### Documentation Standards

**Required Documentation**:
- Architecture in [Docs/Architecture.md](../Docs/Architecture.md)
- Testing guidelines in [Docs/Testing.md](../Docs/Testing.md)
- Pull request template: [.github/PULL_REQUEST_TEMPLATE.md](../.github/PULL_REQUEST_TEMPLATE.md)
- ADRs for significant decisions (see [Contributing Guide](https://contributing.bitwarden.com/architecture/adr/))

**Documentation Format**:
- Markdown for all documentation
- Use relative paths for internal links
- Include code examples where applicable
- Link to external Bitwarden contributing docs when appropriate

#### Security Considerations

**Critical Security Rules**:
- No vault data in logs or error messages
- All encryption/decryption via Bitwarden SDK
- Never commit `.env`, credentials, or secrets
- Use Keychain for sensitive data storage
- Follow [Security Definitions](https://contributing.bitwarden.com/architecture/security/definitions)

**Data Classification**:
- Vault data: Always encrypted at rest and in transit
- User credentials: Keychain only
- Session tokens: Secure storage with appropriate expiration
- Biometric data: OS-managed only

#### Quick Reference Files

- **Project Instructions**: [CLAUDE.md](../CLAUDE.md)
- **Architecture**: [Docs/Architecture.md](../Docs/Architecture.md)
- **Testing Guide**: [Docs/Testing.md](../Docs/Testing.md)
- **Contributing**: [CONTRIBUTING.md](../CONTRIBUTING.md)
- **PR Template**: [.github/PULL_REQUEST_TEMPLATE.md](../.github/PULL_REQUEST_TEMPLATE.md)
- **Code Style**: [Swift Code Style](https://contributing.bitwarden.com/contributing/code-style/swift/)
- **Security**: [Security Whitepaper](https://bitwarden.com/help/bitwarden-security-white-paper/)

## Configuration

### Settings File (`settings.local.json`)
Configure Claude Code integration with agents:
```json
{
  "hooks": {
    "on_subagent_stop": ".claude/hooks/on-subagent-stop.sh",
    "on_stop": ".claude/hooks/on-stop.sh"
  }
}
```

### Agent Definitions
Agents are defined in markdown files in the `agents/` directory with YAML frontmatter:
```yaml
---
name: "Agent Name"
description: "Agent description"
tools: ["Read", "Write", "Edit"]
---
```

## Troubleshooting

### Hook Execution Issues
- Verify hook scripts are executable: `chmod +x .claude/hooks/*.sh`
- Check JSON syntax in `settings.local.json`
- Review hook output in Claude Code console

### Agent Selection Confusion
- Review agent specifications in `.claude/agents/` directory
- Check hook suggestions for guidance
- Consult [AGENT_ROLE_MAPPING.md](AGENT_ROLE_MAPPING.md)

### Status Transition Problems
- Verify agents output correct status markers
- Check hook logic for status recognition
- Manual intervention may be required for custom workflows

## Directory Structure

```
.claude/
├── agents/              # Agent definitions
│   ├── requirements-analyst.md
│   ├── architect.md
│   ├── implementer.md
│   ├── tester.md
│   ├── documenter.md
│   └── agents.json     # Generated agent registry
├── hooks/              # Workflow automation hooks
│   ├── on-subagent-stop.sh
│   └── on-stop.sh
├── queues/             # Task queue management
│   ├── queue_manager.sh
│   ├── task_queue.json
│   └── workflow_templates.json
├── status/             # Workflow state tracking
│   └── workflow_state.json
├── logs/               # Operation logs
│   └── queue_operations.log
└── [documentation files]
```

## Future Extensions

The system is designed for extensibility:
- Additional specialized agents can be added to `agents/`
- New hooks can be created for custom workflows
- Agent tools and permissions can be adjusted as needed
- Status markers and workflow transitions can be customized
- Workflow templates can be added for project-specific patterns

## Learn More

- [AGENT_ROLE_MAPPING.md](AGENT_ROLE_MAPPING.md) - Detailed agent role descriptions
- [TASK_PROMPT_DEFAULTS.md](TASK_PROMPT_DEFAULTS.md) - Standard task prompt templates
- [QUEUE_SYSTEM_GUIDE.md](QUEUE_SYSTEM_GUIDE.md) - Complete queue system documentation
- [WORKFLOW_STEP_TEMPLATE.md](WORKFLOW_STEP_TEMPLATE.md) - Enhancement workflow template

This multi-agent system enhances your development workflow without disrupting established practices.
