---
description: Plan implementation for a Bitwarden iOS Jira ticket or task description. Fetches requirements, performs gap analysis, designs the implementation approach, and saves a design doc to .claude/outputs/plans/.
argument-hint: <PM-XXXXX ticket ID or task description>
---

# Plan iOS Work: $ARGUMENTS

## Phase 1: Ingest Requirements

If `$ARGUMENTS` looks like a Jira ticket ID (e.g., `PM-12345` or `BWA-456`):
- Fetch the ticket: `mcp__plugin_bitwarden-atlassian-tools_bitwarden-atlassian__get_issue`
- Fetch comments for context: `mcp__plugin_bitwarden-atlassian-tools_bitwarden-atlassian__get_issue_comments`

If `$ARGUMENTS` is a description, use it directly as the requirements source.

## Phase 2: Refine Requirements

Invoke the `refining-ios-requirements` skill to:
- Extract structured requirements and acceptance criteria
- Perform gap analysis (error states, edge cases, extensions, accessibility)
- Map to iOS domain (Auth/Autofill/Platform/Tools/Vault)

**Pause here**: Present requirements to user and confirm accuracy before proceeding.

## Phase 3: Plan Implementation

Once requirements are confirmed, invoke the `planning-ios-implementation` skill to:
- Classify the change type
- Explore existing similar patterns in the codebase
- List all files to create/modify with domain placement
- Order implementation into dependency-ordered phases
- Assess risks (security, extensions, multi-account, SDK)

## Phase 4: Save Design Doc

Save the complete plan to `.claude/outputs/plans/<ticket-id>.md`.

**Final output**: "Plan saved to `.claude/outputs/plans/<ticket-id>.md`. Ready to implement with `/work-on-ios <ticket-id>`."
