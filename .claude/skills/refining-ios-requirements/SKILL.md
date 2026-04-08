---
name: refining-ios-requirements
description: Refine requirements, analyze a ticket, perform gap analysis, or clarify what a Jira/Confluence ticket is asking before coding in Bitwarden iOS. Use when asked to "refine requirements", "analyze ticket", "gap analysis", "clarify ticket", "what does this ticket mean", or to understand scope before implementation begins.
---

# Refining iOS Requirements

Use this skill to analyze a Jira or Confluence ticket and produce structured, implementation-ready requirements before writing any code.

## Step 1: Ingest the Ticket

If a ticket ID or URL is provided, fetch it via MCP:
- Use `mcp__plugin_bitwarden-atlassian-tools_bitwarden-atlassian__get_issue` for Jira tickets
- Use `mcp__plugin_bitwarden-atlassian-tools_bitwarden-atlassian__get_issue_comments` for additional context
- Use `mcp__plugin_bitwarden-atlassian-tools_bitwarden-atlassian__get_confluence_page` for Confluence specs

If no ticket is provided, ask for a description of the requirements.

## Step 2: Extract Requirements

Identify and list:
1. **Core functionality**: What must this feature/fix do?
2. **Acceptance criteria**: What defines "done"?
3. **Out of scope**: What is explicitly excluded?
4. **Dependencies**: Other tickets, SDK changes, API endpoints needed?

## Step 3: Gap Analysis

Identify unstated requirements the ticket may have missed:

**Error states**
- Network errors, timeout, server errors
- Validation failures, empty states
- SDK errors (encryption/decryption failures)

**Edge cases**
- Multi-account scenarios (up to 5 accounts)
- Account switching during the operation
- Locked vs unlocked vault state
- Empty vault / first-time user

**Platform concerns**
- App extension impact (AutoFill, Action, Share — memory limits apply)
- watchOS companion impact (if vault data is involved, especially TOTP data)
- Offline mode behavior

**Accessibility**
- VoiceOver labels for new UI elements
- Dynamic Type support
- Keyboard navigation

## Step 4: Map to iOS Domain

Determine which Bitwarden iOS domain(s) are involved. Read `Docs/Architecture.md` (Architecture Structure section) for the canonical domain list and descriptions.

Determine which app(s) are affected:
- **BitwardenShared**: Password Manager
- **AuthenticatorShared**: Authenticator
- **Both**: If the feature touches shared components

## Step 5: Output Structured Requirements

```markdown
## Ticket: [PM-XXXXX] — [Title]

### What
[1-2 sentence summary of what needs to be built]

### Why
[Business/user reason for the change]

### Acceptance Criteria
1. [Criterion 1]
2. [Criterion 2]

### Gap Analysis
**Unstated requirements identified:**
- [ ] Error state: [description]
- [ ] Edge case: [description]
- [ ] Platform concern: [description]

**Clarifying questions (if any):**
1. [Question for product/design]

### Scope
- **Domain**: [from Architecture Structure domain list]
- **App(s)**: [Password Manager / Authenticator / Both]
- **Extensions affected**: [AutoFill / Action / Share / Watch / None]
- **Out of scope**: [explicit exclusions]
```

## Confirm Before Proceeding

Present the structured requirements to the user and ask: "Are these requirements accurate? Should I proceed with planning the implementation?"
