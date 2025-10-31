---
name: reviewing-changes
description: Performs comprehensive code reviews for Bitwarden iOS projects, verifying architecture compliance, style guidelines, compilation safety, test coverage, and security requirements. Use when reviewing pull requests, checking commits, analyzing code changes, verifying Bitwarden coding standards, evaluating unidirectional data flow pattern, checking services container dependency injection usage, reviewing security implementations, or assessing test coverage. Automatically invoked by CI pipeline or manually for interactive code reviews.
---

# Reviewing Changes

## Instructions

Follow this process to review code changes for Bitwarden iOS:

### Step 1: Understand Context

Start with high-level assessment of the change's purpose and approach. Read PR/commit descriptions and understand what problem is being solved.

### Step 2: Verify Compliance

Systematically check each area against Bitwarden standards documented in `CLAUDE.md`:

1. **Architecture**: Follow patterns in `Docs/Architecture.md`
   - Unidirectional data flow Coordinators + Processors (using SwiftUI)
   - Dependency Injection using `ServiceContainer`
   - Repository pattern and proper data flow

2. **Style**: Adhere to [Code Style](https://contributing.bitwarden.com/contributing/code-style/swift)
   - Naming conventions, code organization, formatting
   - Swift/SwiftUI guidelines

3. **Compilation**: Analyze for potential build issues
   - Import statements and dependencies
   - Type safety and null safety
   - API compatibility and deprecation warnings
   - Resource/SDK references and requirements

4. **Testing**: Verify appropriate test coverage
   - Unit tests for business logic and utility functions
   - Snapshot/View inspector tests for user-facing features when applicable
   - Test coverage for edge cases and error scenarios

5. **Security**: Given Bitwarden's security-focused nature
   - Proper handling of sensitive data
   - Secure storage practices (Keychain)
   - Authentication and authorization patterns
   - Data encryption and decryption flows
   - Zero-knowledge architecture preservation

### Step 3: Document Findings

Identify specific violations with `file:line_number` references. Be precise about locations.

### Step 4: Provide Recommendations

Give actionable recommendations for improvements. Explain why changes are needed and suggest specific solutions.

### Step 5: Flag Critical Issues

Highlight issues that must be addressed before merge. Distinguish between blockers and suggestions.

### Step 6: Acknowledge Quality

Note well-implemented patterns (briefly, without elaboration). Keep positive feedback concise.

## Review Anti-Patterns (DO NOT)

- Be nitpicky about linter-catchable style issues
- Review without understanding context - ask for clarification first
- Focus only on new code - check surrounding context for issues
- Request changes outside the scope of this changeset

## Examples

### Good Review Format

```markdown
## Summary
This PR adds biometric authentication to the login flow, implementing unidirectional data flow pattern with proper state management.

## Critical Issues
- `BitwardenShared/UI/Auth/Login/LoginView.swift:25` - No `scrollView` added, user can't scroll through the view.
- `BitwardenShared/Core/Auth/Services/AuthService.swift:120` - You must not use `try!`, change it to `try` in a `do...catch` block or throwing function.

## Suggested Improvements
- Consider extracting biometric prompt logic to separate struct
- Add missing tests for biometric failure scenarios
- `BitwardenShared/UI/Auth/Login/LoginView.swift:43` - Consider using existing `BitwardenTextField` component

## Good Practices
- Proper comments documentation
- Comprehensive unit test coverage
- Clear separation of concerns

## Action Items
1. Add scroll view in `LoginView`
2. Change `try!` to `try` in `AuthService`
3. Consider adding tests for error flows
```

### What to Focus On

**DO focus on:**
- Architecture violations (incorrect patterns)
- Security issues (data handling, encryption)
- Missing tests for critical paths
- Compilation risks (type safety, null safety)

**DON'T focus on:**
- Minor formatting (handled by linters)
- Personal preferences without architectural basis
- Issues outside the changeset scope
