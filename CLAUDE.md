# Bitwarden iOS - Claude Code Configuration

## Project Context Files

**Read these files before reviewing to ensure that you fully understand the project and contributing guidelines**

1. @README.md
2. @CONTRIBUTING.md
3. @.github/PULL_REQUEST_TEMPLATE.md


## Project Structure Quick Reference

- **BitwardenShared/**: Main codebase (Core + UI layers)
  - **Core/**: Data layer (Models, Services, Repositories, Stores)
  - **Sourcery/**: Sourcery related files, including auto generated mocks.
  - **UI/**: Presentation layer (Coordinators, Processors, Views, State)
- **AuthenticatorShared/**: Same as `BitwardenShared` but for Authenticator app.
- **Domains**: Auth | Autofill | Platform | Tools | Vault
- **Apps**: The projects contain two main apps: "Password Manager" and "Authenticator".
  - **
- **Main Password Manager targets**: Bitwarden, BitwardenActionExtension, BitwardenAutoFillExtension, BitwardenShareExtension, BitwardenWatchApp, BitwardenWatchWidgetExtension
- **Main Authenticator target**: Authenticator
- **Shared apps frameworks**: BitwardenKit, BitwardenKitMocks, BitwardenResources, AuthenticatorBridgeKit, AuthenticatorBridgeKitMocks, Networking, TestHelpers

## Critical Rules

- **NEVER** install third-party libaries unless explicitly told to.
- **CRITICAL**: new encryption logic should not be added to this repo.
- **NEVER** send unencrypted vault data to API services
- **NEVER** commit secrets, credentials, or sensitive information.
- **NEVER** log decrypted data, encryption keys, or PII
  - No vault data in error messages or console logs
- **ALWAYS** Read "iOS Client Architecture" and "Code Style" in References before answer.

## Common Patterns

- **UI changes**: Always follow Coordinator → Processor → State → View flow
- **Data access**: UI layer mostly uses Repositories (never Stores directly and scarsely Services)
- **State mutations**: Only in Processors
- **Navigation**: Coordinators handle navigation via Routes/Events enums
- **Testing**: Test file goes in same folder as implementation (e.g., `FooProcessor.swift` + `FooProcessorTests.swift`)
- **Mocking**: Mocks should be done on protocols. Prefer to use Sourcery AutoMockable approach by adding `// sourcery: AutoMockable` to the protocol.
- **Dependencies**: Use protocol composition via Services typealias

## Anti-Patterns to Avoid

- **NEVER** mutate state directly in Views
- **NEVER** put business logic in Coordinators
- **NEVER** access Stores from UI layer (use Repositories)
- **NEVER** create new top-level folders in Core/ or UI/ (use existing domains)
- **NEVER** use concrete types in Services typealias (use protocols for mocking)

## Common File Locations

- Dependency injection: [BitwardenShared/Core/Platform/Services/ServiceContainer.swift](BitwardenShared/Core/Platform/Services/ServiceContainer.swift)
- App module (coordinator factory): [BitwardenShared/UI/Platform/Application/AppModule.swift](BitwardenShared/UI/Platform/Application/AppModule.swift)
- Store (View-Processor bridge): [BitwardenShared/UI/Platform/Application/Utilities/Store.swift](BitwardenShared/UI/Platform/Application/Utilities/Store.swift)
- Project generation
  - `project-pm.yml`: for main Password Manager
  - `project-bwa.yml`: for Authenticator
  - `project-bwk.yml`: for shared frameworks like Bitwarden Kit

## Testing Requirements

- Every type with logic needs tests
- Test files named `<TypeToTest>Tests.swift` in same folder
- Snapshot tests use device/iOS version from `.test-simulator-device-name` and `.test-simulator-ios-version`
- Test in light mode, dark mode, and large dynamic type

## References

When searching for references of https://contributing.bitwarden.com, first check if there's a local copy on ../ContributingDocs/src.

- [iOS Client Architecture](https://contributing.bitwarden.com/architecture/mobile-clients/ios/)
- [Code Style](https://contributing.bitwarden.com/contributing/code-style/swift)
- [Architectural Decision Records (ADRs)](https://contributing.bitwarden.com/architecture/adr/)
- [Contributing Guide](https://contributing.bitwarden.com/)
- [iOS Client Setup Guide](https://contributing.bitwarden.com/getting-started/mobile/ios/)
- [Security Whitepaper](https://bitwarden.com/help/bitwarden-security-white-paper/)
- [Security Definitions](https://contributing.bitwarden.com/architecture/security/definitions)
- [Accessibility](https://contributing.bitwarden.com/contributing/accessibility/)