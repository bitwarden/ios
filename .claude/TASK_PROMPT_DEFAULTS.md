# Task Prompt Templates

This file contains standardized prompt templates for different task types in the multi-agent workflow system.

## Template Variables

The following variables are automatically substituted in templates when launching agents via queue_manager.sh:

- `${agent}` - The agent name executing the task
- `${agent_config}` - Path to the agent's configuration file (.md file)
- `${source_file}` - The source document to process (enhancement file, analysis doc, etc.)
- `${task_description}` - Specific task instructions provided when creating the task
- `${task_id}` - Unique identifier for this task
- `${task_type}` - Type of task (ANALYSIS, TECHNICAL_ANALYSIS, IMPLEMENTATION, TESTING, DOCUMENTATION)

## How This Works

When you use queue_manager.sh to create a task:

```bash
.claude/queues/queue_manager.sh add \
  "Analyze feature X" \
  "requirements-analyst" \
  "high" \
  "Process the requirements in enhancements/feature-x/feature.md" \
  --source-file="enhancements/feature-x/feature.md" \
  --task-type="ANALYSIS"
```

The queue manager will:
1. Look up the ANALYSIS_TEMPLATE below
2. Substitute all ${variables} with actual values
3. Pass the complete prompt to Claude Code when you start the task

---

# ANALYSIS_TEMPLATE

You are acting as the ${agent} agent performing requirements analysis.

Read your role definition from: ${agent_config}

Process this source file: ${source_file}

## ANALYSIS OBJECTIVES:
- Extract and clarify all requirements from the source document
- Identify dependencies, constraints, and potential issues
- Flag any ambiguities or missing information that need clarification
- Create structured analysis outputs (requirements documents, analysis reports)
- Assess feasibility and identify technical risks

## SPECIFIC TASK:
${task_description}

## ANALYSIS METHODOLOGY:
1. **Document Review**: Thoroughly read and understand the source document
2. **Requirement Extraction**: Identify functional and non-functional requirements
3. **Dependency Analysis**: Map dependencies between components and external systems
4. **Risk Assessment**: Identify potential technical, architectural, or implementation risks
5. **Gap Analysis**: Note missing information or unclear specifications
6. **Documentation**: Create clear, structured analysis outputs

Document your analysis process, decisions, and reasoning as you work through the requirements.

## REQUIRED OUTPUT DIRECTORY AND DOCUMENT:
You MUST create a subdirectory named `${agent}` in the same directory as the source file, and write all your output files there.

**Output Directory**: `<source_file_directory>/${agent}/`

Example: If source file is `enhancements/add-json-export/add-json-export.md`, create directory `enhancements/add-json-export/requirements-analyst/`

**Primary Output Document**: Create `analysis_summary.md` in your agent subdirectory. This serves as the primary handoff document to the next phase. This file should:
- Summarize all key findings and requirements identified
- Reference any additional documents you created during analysis (also in your subdirectory)
- Provide clear next steps for the architecture/design phase
- Include any constraints, dependencies, or risks identified

The `<source_file_directory>/requirements-analyst/analysis_summary.md` file will be used as the source document for the technical analysis phase.

IMPORTANT: You have full permission to create all required directories and output files using the Write tool. Do not ask for permission - directly create and write all files to their specified locations. This is an automated workflow system and file creation is expected and authorized.

When complete, output your status as one of:
- READY_FOR_DEVELOPMENT (requirements are clear and complete)
- COMPLETED (analysis is finished with recommendations)
- BLOCKED: <reason> (cannot proceed due to missing information or other issues)

Task ID: ${task_id}

---

# TECHNICAL_ANALYSIS_TEMPLATE

You are acting as the ${agent} agent performing technical analysis and system design.

Read your role definition from: ${agent_config}

Process this source file: ${source_file}

## TECHNICAL ANALYSIS OBJECTIVES:
- Design system architecture and technical approach
- Make technology stack and framework decisions
- Define interfaces, APIs, and data structures
- Create detailed technical specifications and implementation plans
- Address performance, scalability, and maintainability concerns

## SPECIFIC TASK:
${task_description}

## TECHNICAL ANALYSIS METHODOLOGY:
1. **Architecture Design**: Define overall system structure and component relationships
2. **Technology Selection**: Choose appropriate tools, frameworks, and technologies
3. **Interface Design**: Specify APIs, data formats, and integration points
4. **Performance Analysis**: Consider scalability, performance, and resource requirements
5. **Implementation Planning**: Break down work into implementable components
6. **Documentation**: Create technical specifications and architecture documents

Focus on creating implementable, maintainable solutions that meet the analyzed requirements.

Document your technical decisions, trade-offs, and reasoning as you design the system.

## REQUIRED OUTPUT DIRECTORY AND DOCUMENT:
You MUST create a subdirectory named `${agent}` in the same directory as the source file, and write all your output files there.

**Output Directory**: `<source_file_directory>/${agent}/`

Example: If source file is `enhancements/add-json-export/requirements-analyst/analysis_summary.md`, create directory `enhancements/add-json-export/architect/`

**Primary Output Document**: Create `implementation_plan.md` in your agent subdirectory. This serves as the primary handoff document to the implementation phase. This file should:
- Provide detailed, step-by-step implementation instructions
- Specify exact files to modify and what changes to make
- Include code snippets, API specifications, and technical details
- Reference any additional technical documents you created (also in your subdirectory)
- Define acceptance criteria and validation steps

The `<source_file_directory>/architect/implementation_plan.md` file will be used as the source document for the implementation phase.

IMPORTANT: You have full permission to create all required directories and output files using the Write tool. Do not ask for permission - directly create and write all files to their specified locations. This is an automated workflow system and file creation is expected and authorized.

When complete, output your status as one of:
- READY_FOR_IMPLEMENTATION (design is complete and implementable)
- READY_FOR_TESTING (technical analysis complete, needs validation)
- COMPLETED (technical analysis finished with recommendations)
- BLOCKED: <reason> (cannot proceed due to technical constraints or missing information)

Task ID: ${task_id}

---

# IMPLEMENTATION_TEMPLATE

You are acting as the ${agent} agent performing hands-on implementation and code changes.

Read your role definition from: ${agent_config}

Process this source file: ${source_file}

## IMPLEMENTATION OBJECTIVES:
- Execute the technical design by making actual code changes
- Create, modify, or update source files according to specifications
- Implement features, fix bugs, or refactor code as specified
- Ensure code follows project conventions and quality standards
- Test implementations to verify they work correctly

## SPECIFIC TASK:
${task_description}

## IMPLEMENTATION METHODOLOGY:
1. **Specification Review**: Understand exactly what needs to be implemented
2. **Code Planning**: Plan the specific changes needed in each file
3. **Implementation**: Make the actual code changes using appropriate tools
4. **Quality Check**: Ensure code follows project standards and conventions
5. **Basic Testing**: Verify the implementation works as expected
6. **Documentation**: Update relevant code documentation and comments

Focus on creating working, maintainable code that fulfills the technical specifications.

Document your implementation decisions and any issues encountered during development.

## REQUIRED OUTPUT DIRECTORY AND DOCUMENT:
You MUST create a subdirectory named `${agent}` in the same directory as the source file, and write all your output files there.

**Output Directory**: `<source_file_directory>/${agent}/`

Example: If source file is `enhancements/add-json-export/architect/implementation_plan.md`, create directory `enhancements/add-json-export/implementer/`

**Primary Output Document**: Create `test_plan.md` in your agent subdirectory. This serves as the primary handoff document to the testing phase. This file should:
- Document what was implemented and how it works
- Provide comprehensive test scenarios and test cases
- Include specific testing instructions and expected results
- Reference all code changes and files modified
- List any known issues, limitations, or areas requiring special attention

The `<source_file_directory>/implementer/test_plan.md` file will be used as the source document for the testing phase.

IMPORTANT: You have full permission to create all required directories and output files using the Write tool. Do not ask for permission - directly create and write all files to their specified locations. This is an automated workflow system and file creation is expected and authorized.

When complete, output your status as one of:
- READY_FOR_TESTING (implementation complete, needs comprehensive testing)
- READY_FOR_INTEGRATION (implementation complete, needs integration)
- IMPLEMENTATION_COMPLETE (implementation finished and verified)
- BLOCKED: <reason> (cannot proceed due to technical issues or missing dependencies)

Task ID: ${task_id}

---

# TESTING_TEMPLATE

You are acting as the ${agent} agent performing testing and quality assurance.

Read your role definition from: ${agent_config}

Process this source file: ${source_file}

## TESTING OBJECTIVES:
- Validate that implementations meet requirements and specifications
- Create and execute comprehensive test plans
- Verify functionality, performance, and integration points
- Identify and document any bugs, issues, or regressions
- Ensure quality standards are met before completion

## SPECIFIC TASK:
${task_description}

## TESTING METHODOLOGY:
1. **Test Planning**: Define test strategy and create test cases
2. **Unit Testing**: Test individual components and functions
3. **Integration Testing**: Verify components work together correctly
4. **Functional Testing**: Validate that features work as specified
5. **Regression Testing**: Ensure existing functionality still works
6. **Documentation**: Record test results and any issues found

Focus on thorough validation to ensure high-quality, reliable implementations.

Document your testing approach, results, and any issues discovered during testing.

## REQUIRED OUTPUT DIRECTORY AND DOCUMENT:
You MUST create a subdirectory named `${agent}` in the same directory as the source file, and write all your output files there.

**Output Directory**: `<source_file_directory>/${agent}/`

Example: If source file is `enhancements/add-json-export/implementer/test_plan.md`, create directory `enhancements/add-json-export/tester/`

**Primary Output Document**: Create `test_summary.md` in your agent subdirectory. This serves as the final deliverable document for the completed feature. This file should:
- Summarize all test results and validation outcomes
- Document any issues found and their resolution status
- Provide final acceptance criteria verification
- Include test coverage metrics and quality assessments
- Reference all test artifacts and test code created (also in your subdirectory)
- Provide final recommendations or next steps

The `<source_file_directory>/tester/test_summary.md` file serves as the final completion record for the entire workflow.

IMPORTANT: You have full permission to create all required directories and output files using the Write tool. Do not ask for permission - directly create and write all files to their specified locations. This is an automated workflow system and file creation is expected and authorized.

When complete, output your status as one of:
- TESTING_COMPLETE (testing complete, implementation validated)
- READY_FOR_INTEGRATION (testing complete, ready for broader integration)
- BLOCKED: <reason> (cannot proceed due to test failures or missing test dependencies)

Task ID: ${task_id}

# INTEGRATION_TEMPLATE

You are acting as the ${agent} agent performing integration with external systems.

Read your role definition from: ${agent_config}

Process this source file: ${source_file}

## INTEGRATION OBJECTIVES:
- Synchronize internal workflow state with external tracking systems
- Create or update GitHub issues, pull requests, and labels
- Create or update Jira tickets with appropriate status
- Publish documentation to Confluence when appropriate
- Maintain bidirectional links between internal tasks and external items
- Store external IDs for future reference and updates

## SPECIFIC TASK:
${task_description}

## INTEGRATION METHODOLOGY:
1. **Context Analysis**: Review the source file to understand what was accomplished
2. **Determine Actions**: Based on workflow status, decide what external updates are needed
3. **GitHub Operations**: Create issues, PRs, or update labels as appropriate
4. **Jira Operations**: Create or update tickets, transition status
5. **Confluence Operations**: Publish documentation pages when needed
6. **Metadata Storage**: Store all external IDs for future reference
7. **Cross-Linking**: Ensure all platforms link to each other appropriately

## AVAILABLE MCP TOOLS:
You have access to the following MCP servers through tool calls:
- **github-mcp**: For GitHub operations (issues, PRs, labels, comments)
- **atlassian-mcp**: For Jira and Confluence operations

## WORKFLOW STATUS MAPPING:

### READY_FOR_DEVELOPMENT
**Actions:**
- Create GitHub issue with feature description and acceptance criteria
- Add labels: `enhancement`, `ready-for-dev`
- Create Jira ticket (Story or Task) with summary and description
- Link GitHub issue to Jira ticket
- Store issue/ticket IDs in task metadata

**Example GitHub Issue:**
```
Title: [Feature] Add JSON Export Functionality
Body: 
## Description
[Summary from requirements]

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Related
Jira: PROJECT-123
```

### READY_FOR_IMPLEMENTATION
**Actions:**
- Update GitHub issue: add label `architecture-complete`
- Comment on issue with architecture summary
- Update Jira ticket status to "In Progress"
- Add comment with technical approach

### READY_FOR_TESTING
**Actions:**
- Create GitHub Pull Request
- Reference original issue: "Closes #123"
- Add PR description with implementation summary
- Add label `ready-for-review`
- Update Jira ticket with PR link
- Transition Jira to "In Review"

**Example PR:**
```
Title: Implement JSON export feature
Body:
## Summary
[Implementation summary]

## Changes
- Added JSONExporter class
- Updated CLI interface
- Added export tests

## Testing
- Unit tests: ✓
- Integration tests: ✓

Closes #123
Related Jira: PROJECT-456
```

### TESTING_COMPLETE
**Actions:**
- Comment on PR with test results
- Add label `tests-passing` to PR
- Update Jira ticket with test summary
- Transition Jira to "Testing" status

### DOCUMENTATION_COMPLETE
**Actions:**
- Publish documentation to Confluence
- Update README if needed
- Merge PR (if appropriate)
- Close GitHub issue
- Transition Jira ticket to "Done"
- Add final comments with links to documentation

## ERROR HANDLING:

If an MCP operation fails:
1. Log the specific error clearly
2. Determine if the operation is retryable
3. Continue with other operations if possible
4. Report partial success with details

**Output format for errors:**
```
INTEGRATION_FAILED

Error: GitHub API rate limit exceeded (resets in 15 minutes)

Partial Success:
- Jira ticket created: PROJECT-456
- GitHub operations pending (will retry)

Manual Steps:
1. Wait 15 minutes for rate limit reset
2. Retry: queue_manager.sh retry ${task_id}
```

## METADATA TRACKING:

After successful operations, you should work with the queue manager to store external IDs.
The queue manager has an `update-metadata` command for this purpose.

**Important IDs to track:**
- `github_issue`: GitHub issue number (e.g., "145")
- `github_issue_url`: Full URL to issue
- `jira_ticket`: Jira ticket key (e.g., "PROJECT-892")
- `jira_ticket_url`: Full URL to ticket
- `github_pr`: PR number (when created)
- `github_pr_url`: Full URL to PR
- `confluence_page`: Confluence page ID
- `confluence_url`: Full URL to page

## REQUIRED OUTPUT FORMAT:

Create a summary document in your agent subdirectory documenting what was integrated.

**Output Directory**: `<source_file_directory>/${agent}/`

**Primary Output Document**: Create `integration_summary.md` in your agent subdirectory with:
- What external items were created/updated
- All external IDs and URLs
- Cross-references between systems
- Any errors or partial failures
- Manual steps required (if any)

## CROSS-PLATFORM LINKING:

Always maintain bidirectional links:
- GitHub issues → Jira tickets (in issue description)
- Jira tickets → GitHub issues (as web link)
- PRs → Both GitHub issues and Jira tickets
- Confluence pages → Both GitHub and Jira

**Linking format:**
- GitHub: "Related Jira: PROJECT-123" or "Jira: [PROJECT-123](url)"
- Jira: Use Web Links feature or comments with "GitHub Issue: #123"
- Confluence: Use macro or links section

## IMPORTANT NOTES:

- **Never duplicate**: Check if issue/ticket already exists before creating
- **Update, don't recreate**: Use stored IDs to update existing items
- **Be idempotent**: Safe to run multiple times without creating duplicates
- **Handle rate limits**: GitHub and Jira have API rate limits
- **Store everything**: All external IDs must be tracked for future operations
- **Cross-link**: Every external item should link to related items in other systems

## CONFIGURATION REQUIREMENTS:

Ensure these are available (check MCP server configs):
- GitHub token with repo scope
- Jira credentials (email + API token)
- Repository owner and name
- Jira project key
- Confluence space key (for documentation)

If configuration is missing, output:
```
INTEGRATION_FAILED

Configuration Error: Missing GitHub repository configuration

Required: GITHUB_REPO in MCP config
Example: "owner/repo-name"

Cannot proceed until configuration is provided.
```

## SUCCESS OUTPUT:

When complete, output your status as:

**`INTEGRATION_COMPLETE`**

Include a clear summary:
```
INTEGRATION_COMPLETE

GitHub Issue: #145
https://github.com/owner/repo/issues/145

Jira Ticket: PROJECT-892
https://company.atlassian.net/browse/PROJECT-892

Summary:
- Created GitHub issue with 3 labels
- Created linked Jira ticket in Sprint 12
- Both platforms linked bidirectionally

Next Steps:
- Issue ready for development
- Ticket assigned to current sprint
```

Task ID: ${task_id}

---

## Integration Example Scenarios

### Scenario 1: Requirements Complete
**Input**: READY_FOR_DEVELOPMENT status, requirements document
**Actions**:
1. Read requirements document
2. Extract title and acceptance criteria
3. Create GitHub issue
4. Create Jira ticket
5. Link them together
6. Store both IDs in task metadata

### Scenario 2: Implementation Complete  
**Input**: READY_FOR_TESTING status, implementation plan
**Actions**:
1. Get GitHub issue ID from task metadata
2. Create PR that references issue
3. Get Jira ticket ID from task metadata
4. Update Jira ticket status
5. Add PR link to Jira
6. Store PR ID in task metadata

### Scenario 3: Testing Complete
**Input**: TESTING_COMPLETE status, test summary
**Actions**:
1. Get PR ID from task metadata
2. Post test results as PR comment
3. Add "tests-passing" label
4. Get Jira ticket ID from task metadata
5. Update Jira with test summary
6. Transition to appropriate status

---

## Troubleshooting Common Issues

### Rate Limits
- GitHub: 5000 requests/hour for authenticated users
- Jira: Varies by plan, typically 10 requests/second
- **Solution**: Wait and retry, implement exponential backoff

### Authentication Failures
- Check token/credentials are correct
- Verify token has required scopes/permissions
- Check token hasn't expired

### Item Not Found
- Verify IDs stored in metadata are correct
- Check item wasn't deleted externally
- Fall back to creating new item if appropriate

### Network Issues
- Implement retries with backoff
- Mark as INTEGRATION_FAILED with clear error
- Provide manual recovery steps

---

IMPORTANT: You have full permission to create all required directories and output files using the Write tool. Do not ask for permission - directly create and write all files to their specified locations. This is an automated workflow system and file creation is expected and authorized.
---

# DOCUMENTATION_TEMPLATE

You are acting as the ${agent} agent performing documentation creation and maintenance.

Read your role definition from: ${agent_config}

Process this source file: ${source_file}

## DOCUMENTATION OBJECTIVES:
- Create comprehensive user and developer documentation
- Update existing documentation to reflect changes
- Write clear, accessible documentation for the target audience
- Provide usage examples and code samples
- Ensure documentation accuracy and completeness

## SPECIFIC TASK:
${task_description}

## DOCUMENTATION METHODOLOGY:
1. **Content Review**: Understand what needs to be documented
2. **Audience Analysis**: Identify target audience (users, developers, both)
3. **Writing**: Create clear, well-organized documentation
4. **Examples**: Provide practical usage examples and code samples
5. **Validation**: Verify accuracy of all documentation and examples
6. **Organization**: Ensure logical structure and easy navigation

Focus on creating documentation that helps users understand and use the features effectively.

Document your documentation approach and any clarifications needed.

## REQUIRED OUTPUT DIRECTORY AND DOCUMENT:
You MUST create a subdirectory named `${agent}` in the same directory as the source file, and write all your output files there.

**Output Directory**: `<source_file_directory>/${agent}/`

Example: If source file is `enhancements/add-json-export/tester/test_summary.md`, create directory `enhancements/add-json-export/documenter/`

**Primary Output Document**: Create or update the relevant documentation files. At minimum, create a `documentation_summary.md` file in your agent subdirectory. This should:
- List all documentation files created or updated
- Summarize the documentation changes made
- Note any areas requiring additional documentation
- Provide links to all created/updated documentation
- Include any recommendations for future documentation work

IMPORTANT: You have full permission to create all required directories and output files using the Write tool. Do not ask for permission - directly create and write all files to their specified locations. This is an automated workflow system and file creation is expected and authorized.

When complete, output your status as one of:
- DOCUMENTATION_COMPLETE (documentation finished and comprehensive)
- COMPLETED (documentation work finished with recommendations)
- BLOCKED: <reason> (cannot proceed due to missing information)

Task ID: ${task_id}

---

## Template Usage Examples

### Example 1: Launch Requirements Analysis

```bash
.claude/queues/queue_manager.sh add \
  "Analyze JSON export feature" \
  "requirements-analyst" \
  "high" \
  "analysis" \
  "enhancements/add-json-export/add-json-export.md" \
  "Extract and clarify requirements for JSON export functionality"

# When started, the queue manager constructs the full prompt by substituting:
# ${agent} = "requirements-analyst"
# ${agent_config} = ".claude/agents/requirements-analyst.md"
# ${source_file} = "enhancements/add-json-export/add-json-export.md"
# ${task_description} = "Extract and clarify requirements for JSON export functionality"
# ${task_id} = "task_1234567890_12345"
# ${task_type} = "analysis"
```

### Example 2: Launch Architecture Design

```bash
.claude/queues/queue_manager.sh add \
  "Design JSON export architecture" \
  "architect" \
  "high" \
  "technical_analysis" \
  "enhancements/add-json-export/requirements-analyst/analysis_summary.md" \
  "Design technical architecture for JSON export feature"

# Note: source_file now points to the output from the previous phase
# Output will be written to: enhancements/add-json-export/architect/implementation_plan.md
```

### Example 3: Complete Workflow File Flow

```bash
# Phase 1: Requirements Analysis
# Input: enhancements/add-json-export/add-json-export.md
# Output: enhancements/add-json-export/requirements-analyst/analysis_summary.md

# Phase 2: Architecture Design
# Input: enhancements/add-json-export/requirements-analyst/analysis_summary.md
# Output: enhancements/add-json-export/architect/implementation_plan.md

# Phase 3: Implementation
# Input: enhancements/add-json-export/architect/implementation_plan.md
# Output: enhancements/add-json-export/implementer/test_plan.md

# Phase 4: Testing
# Input: enhancements/add-json-export/implementer/test_plan.md
# Output: enhancements/add-json-export/tester/test_summary.md

# Phase 5: Documentation (optional)
# Input: enhancements/add-json-export/tester/test_summary.md
# Output: enhancements/add-json-export/documenter/documentation_summary.md
```

---

## Customization

To customize these templates for your project:

1. **Add project-specific context** to each template
2. **Adjust output requirements** for your workflow
3. **Add/remove template sections** as needed
4. **Create custom templates** for project-specific task types
5. **Update variable substitution** in queue_manager.sh if needed

Example custom template:

```
# CODE_REVIEW_TEMPLATE

You are acting as the ${agent} agent performing code review.

Read your role definition from: ${agent_config}

Review the code in: ${source_file}

[... custom template content ...]
```

Then use it:

```bash
.claude/queues/queue_manager.sh add \
  "Review implementation" \
  "architect" \
  "high" \
  "code_review" \
  "src/feature.py" \
  "Review code quality and design"
```
