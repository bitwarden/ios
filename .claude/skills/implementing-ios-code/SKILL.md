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
  - Alphabetize stored properties and initializer parameters (parameters with default values go last). When you add one to an existing type, insert it at its alphabetical position and update the synthesized initializer and every call site to match — don't append.
- Enum types in `Core/<Domain>/Models/Enum/`
  - Keep cases alphabetical. When you add a case to an existing enum, insert it at its alphabetical position in **every `switch` over that enum** (across all layers) rather than appending it — match the surrounding order.

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

**SwiftUI previews:**

- Use `#Preview` macros for new views — the modern default across the codebase. Do not add new `PreviewProvider` structs. Because the snapshot harness cannot enumerate `#Preview` macros, such a view's snapshot coverage comes from a test that instantiates the view directly; see the `testing-ios-code` skill for how to choose between that and iterating `PreviewProvider._allPreviews` when a view exposes both.

**New localization keys** (`BitwardenResources/.../Localizable.strings`):

- Key name mirrors the English string: `Archive` for "Archive", not `MoveToArchive` or `ArchiveTitle`.
  - Exception: long descriptive strings (~70-80+ chars) use a `DescriptionLong` suffix on a shortened opening phrase. Example: `PassphrasesAreOftenEasierToRememberDescriptionLong`.
- Translator-facing `/* … */` comments describe meaning, placement, or constraints that affect translation — translators are the audience, not internal engineers.

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

## Step 7: Verify — Lint, Format, and Regenerate

Run these checks after all code and tests are written, **before** handing back. Fix every violation found — do not leave warnings for the commit phase.

**If new localization strings were added**, regenerate first so SwiftGen picks them up:
```bash
mint run swiftgen config run --config swiftgen-bwr.yml   # BitwardenResources (most common)
# Run the appropriate swiftgen-*.yml if strings landed in a different target
```

**Then run the pre-commit checks:**
```bash
./Scripts/pre-commit
```

This runs spell-check, SwiftFormat, and SwiftLint on changed files — the same checks that run at commit time. If violations are reported, fix them and re-run until it passes cleanly.

For SwiftLint violations that require manual fixes, prefer fixing the root cause over suppressing with `// swiftlint:disable` comments. Suppression is appropriate when the violation is structural and fixing it would require an artificial or non-idiomatic refactor. Common cases:
- **`line_length`** — wrap long lines using Xcode's ⌃M style (each argument on its own indented line); fix rather than suppress
- **`file_length`** — if a `#if DEBUG` preview section pushed a file over the limit, add `// swiftlint:disable file_length` at the top of the file (this is the established pattern — do NOT move previews to a separate file)
- **`type_body_length`** — split large types using `// MARK:` extensions in separate files if needed; suppress only if the type is inherently large and splitting would hurt readability

Only hand back once `./Scripts/pre-commit` passes cleanly for files touched in this session.

## Conventions

- **Member ordering** — within a `// MARK:` section, keep members in a single alphabetical order (stored properties, computed properties, methods, and static members share that order), and alphabetize function and initializer parameters the same way (default-valued, variadic, then trailing-closure parameters last). Insert new members and parameters at their alphabetical position rather than appending. Exceptions: UI objects (views, view modifiers) follow visual layout order, not alphabetical; and protocol *conformance* ordering is not enforced.
- **No file-scope globals** — prefer a `static` member on the relevant type or extension over a file-scope global function or property, even a `private` one.
- **Prefer typed over stringly-typed** — model values with their natural types (enums, `Date`, etc.) rather than raw strings, unless deliberately mirroring an external contract (e.g. an SDK model that stores ISO date strings) where typed conversion is intentionally deferred.
