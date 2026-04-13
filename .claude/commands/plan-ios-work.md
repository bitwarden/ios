---
description: Plan implementation for a Bitwarden iOS Jira ticket or task description. Fetches requirements, performs gap analysis, and designs the implementation approach.
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

**Pause here**: Present requirements to user and confirm accuracy before proceeding.

## Phase 3: Plan Implementation

Once requirements are confirmed, invoke the `planning-ios-implementation` skill to:
- Classify the change type
- Explore existing similar patterns in the codebase
- List all files to create/modify with domain placement
- Order implementation into dependency-ordered phases
- Assess risks (security, extensions, multi-account, SDK)

**Final output**: Present the complete plan and suggest using `/work-on-ios` to begin implementation.
