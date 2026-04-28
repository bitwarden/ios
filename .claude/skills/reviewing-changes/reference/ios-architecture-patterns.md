# Architecture Checklist — Bitwarden iOS

Bitwarden-specific structural constraints that reviewers must verify. These are constraints an LLM wouldn't know without project context.

## Unidirectional Data Flow

- [ ] Views only send `Action`/`Effect` — never mutate state directly
- [ ] Business logic lives in `Processor`, not in `Coordinator` or `View`
- [ ] `Coordinator` handles navigation only; route decisions belong in `Processor`
- [ ] State changes flow: `View → Store → Processor → State → View`

## StateProcessor Pattern

- [ ] All feature processors subclass `StateProcessor<State, Action, Effect>`
- [ ] `receive(_ action:)` handles synchronous state mutations
- [ ] `perform(_ effect:)` handles async work (network, persistence)
- [ ] No direct state mutation outside `Processor`

## Dependency Injection

- [ ] `Services` typealias uses only the `Has*` protocols actually needed (no over-injection)
- [ ] New dependencies follow `Has*` prefix protocol pattern
- [ ] `ServiceContainer` is the single DI root — no manual construction of services in views
- [ ] No `any` type for protocol-based dependencies — use generics or `Has*` composition

## Domain Folder Constraints

- [ ] No new top-level subdirectories added to `Core/` or `UI/`
- [ ] Fixed subdirectories only (see `Docs/Architecture.md` Architecture Structure for canonical list)
- [ ] New files placed in the correct domain folder (Auth vs Vault vs Platform)

## File-Set Completeness

When a new screen/feature is added, verify all required files exist:
- [ ] `<Feature>Coordinator.swift`
- [ ] `<Feature>Processor.swift`
- [ ] `<Feature>State.swift`
- [ ] `<Feature>Action.swift`
- [ ] `<Feature>Effect.swift`
- [ ] `<Feature>View.swift`
- [ ] `<Feature>Route.swift` (if navigation is involved — or route case added to parent coordinator)
