---
name: implementing-ios-code
description: Implement, write code, add a new screen, create a feature, new view, new processor, or wire up a new service in Bitwarden iOS. Use when asked to "implement", "write code", "add screen", "create feature", "new view", "new processor", "add service", or when translating a design doc into actual Swift code.
---

# Implementing iOS Code

Use this skill to implement Bitwarden iOS features following established patterns.

## Prerequisites

- A plan should exist in `.claude/outputs/plans/<ticket-id>.md`. If not, invoke `planning-ios-implementation` first.
- Read `Docs/Architecture.md` — it is the authoritative source for all patterns. This skill references it, not replaces it.

## Step 1: Determine Scope

From the plan, identify:
- Is this a new feature (full file-set) or modification of existing code?
- Which framework: `BitwardenShared`, `AuthenticatorShared`, or `BitwardenKit`?
- Which domain: `Auth/`, `Autofill/`, `Platform/`, `Tools/`, `Vault/`?

See `templates.md` for file-set skeletons.

## Step 2: Core Layer First

Implement from the bottom up:

**Data Models** (if needed)
- Request/Response types in `Core/<Domain>/Models/Request/` and `Response/`
- Enum types in `Core/<Domain>/Models/Enum/`

**Persistence** (if needed)
- Vault sync data → CoreData via `DataStore` (add entities to `Bitwarden.xcdatamodeld`)
- Non-sensitive settings → `AppSettingsStore` (backed by UserDefaults)
- Credentials/keys → `KeychainRepository`
- All three are exposed through `StateService`. Prefer adding a separate protocol over extending `StateService`, `AppSettingsStore`, or `KeychainRepository` directly, to maintain interface segregation.

**Services / Repositories**
- Define protocol with `// sourcery: AutoMockable`
- Implement `Default<Name>Service` / `Default<Name>Repository`
- Add `Has<Name>` protocol
- See `templates.md` for service skeleton

## Step 3: UI Layer (File-Set Pattern)

For new screens, create all required files together (see `templates.md`):

1. **Route** — Add case to the parent Coordinator's route enum
2. **Coordinator** — Navigation logic, screen instantiation, `Services` typealias
3. **State** — Value type (`struct`) holding all view-observable data
4. **Action** — Enum of user interactions handled synchronously in `receive(_:)`
5. **Effect** — Enum of async work handled in `perform(_:)`
6. **Processor** — `StateProcessor` subclass, business logic only
7. **View** — SwiftUI view using `store.binding`, `store.perform`, `@ObservedObject`

## Step 4: Wire Dependency Injection

After creating a new service/repository:
- Add `Has<Name>` conformance to `ServiceContainer` via extension
- Add `Has<Name>` to the `Services` typealias of any processor that needs it

## Step 5: Security Check

Before finishing:
- [ ] Vault data? → Must use `BitwardenSdk` for all encryption/decryption
- [ ] Storing credentials? → Must use `KeychainRepository`, not `AppSettingsStore`
- [ ] User input? → Must validate via `InputValidator`
- [ ] Surfacing errors? → Sensitive errors must implement `NonLoggableError`
- [ ] Running in an extension? → Check Argon2id memory if KDF is involved

## Step 6: Documentation

All new public types and methods require DocC (`///`) documentation.
Exceptions: protocol property/function implementations (docs live in the protocol), mock classes.
Use pragma marks to organize code. `// MARK: -` is used to denote different objects in the same file; `// MARK:` is used to denote different sections within an object.
