# Bitwarden iOS Password Manager & Authenticator Apps Claude Guidelines

Core directives for maintaining code quality and consistency in the Bitwarden iOS project.

## Core Directives

**You MUST follow these directives at all times.**

1. **Adhere to Architecture**: All code modifications MUST follow patterns in `./../Docs/Architecture.md`
2. **Follow Code Style**: ALWAYS follow https://contributing.bitwarden.com/contributing/code-style/swift
3. **Follow Testing Guidelines**: Analyzing or implementing tests MUST follow guidelines in `./../Docs/Testing.md`.
4. **Best Practices**: Follow Swift / SwiftUI general best practices (value over reference types, guard clauses, extensions, protocol oriented programming)
5. **Document Everything**: Everything in the code requires DocC documentation except for protocol properties/functions implementations as the docs for them will be in the protocol. Additionally, mocks do not need DocC documentation, because the docs for the public interface will be in the protocol.
6. **Dependency Management**: Use `ServiceContainer` as established in the project
7. **Use Established Patterns**: Leverage existing components before creating new ones
8. **File References**: Use file:line_number format when referencing code

## Security Requirements

**Every change must consider:**
- Zero-knowledge architecture preservation
- Proper encryption key handling (iOS Keychain)
- Input validation and sanitization
- Secure data storage patterns
- Threat model implications

## Workflow Practices

### Before Implementation

1. Read relevant architecture documentation
2. Search for existing patterns to follow
3. Identify affected targets and dependencies
4. Consider security implications

### During Implementation

1. Follow existing code style in surrounding files
2. Write tests alongside implementation
3. Add DocC to everything except protocol implementations and mocks
4. Validate against architecture guidelines

### After Implementation

1. Ensure all tests pass
2. Verify compilation succeeds
3. Review security considerations
4. Update relevant documentation

## Anti-Patterns

**Avoid these:**
- Creating new patterns when established ones exist
- Exception-based error handling in business logic
- Direct dependency access (use DI)
- Undocumented public APIs
- Tight coupling between targets

## Communication & Decision-Making

Always clarify ambiguous requirements before implementing. Use specific questions:
- "Should this use [Approach A] or [Approach B]?"
- "This affects [X]. Proceed or review first?"
- "Expected behavior for [specific requirement]?"

Defer high-impact decisions to the user:
- Architecture/module changes, public API modifications
- Security mechanisms, database migrations
- Third-party library additions

## References

### Critical resources:
- `./../Docs/Architecture.md` - Architecture patterns and principles
- `./../Docs/Testing.md` - Testing guidelines
- https://contributing.bitwarden.com/contributing/code-style/swift - Code style guidelines

**Do not duplicate information from these files - reference them instead.**

### Additional resources:
-   [Architectural Decision Records (ADRs)](https://contributing.bitwarden.com/architecture/adr/)
-   [Contributing Guidelines](https://contributing.bitwarden.com/contributing/)
-   [Accessibility](https://contributing.bitwarden.com/contributing/accessibility/)
-   [Setup Guide](https://contributing.bitwarden.com/getting-started/mobile/ios/)
-   [Security Whitepaper](https://bitwarden.com/help/bitwarden-security-white-paper/)
-   [Security Definitions](https://contributing.bitwarden.com/architecture/security/definitions)
