---
name: planning-ios-implementation
description: Plan implementation, design an approach, or create an architecture plan for a Bitwarden iOS feature. Use when asked to "plan implementation", "design approach", "architecture plan", "how should I implement", "what files do I need", or to create a design doc before writing code.
---

# Planning iOS Implementation

Use this skill to design a complete implementation plan before writing code. Output is saved as a design document.

## Prerequisites

- Requirements must be clear. If not, invoke `refining-ios-requirements` first.
- Read `Docs/Architecture.md` before proceeding — it is the authoritative source for all patterns.

## Step 1: Classify the Change

Determine the change type to guide scope and planning depth:

| Type | Description | Typical Scope |
|------|-------------|---------------|
| **New Feature** | Entirely new functionality, screens, or flows | New files + modifications, multi-phase |
| **Enhancement** | Extending existing feature with new capabilities | Mostly modifications, 1-2 phases |
| **Bug Fix** | Correcting incorrect behavior | Targeted modifications, single phase |
| **Refactoring** | Restructuring without behavior change | Modifications only, migration-aware |
| **Infrastructure** | Build, CI, tooling, or dependency changes | Config files, minimal code changes |

State the classification and rationale before proceeding.

## Step 2: Explore Existing Patterns

Search the codebase for similar existing implementations to follow:
- Find a similar existing feature in the same domain
- Identify which services/repositories it uses
- Note how its Coordinator, Processor, and View are structured
- Check if `BitwardenKit/UI/` has reusable components for the new UI

## Step 3: List Files to Create/Modify

For each file, specify path, action (create/modify), domain placement, and purpose. Group by layer:

```
### New Files (Create)

#### Core Layer
- `BitwardenShared/Core/<Domain>/<Feature>/Services/<Feature>Service.swift`
  - Protocol + Default<Feature>Service + Has<Feature>Service

#### UI Layer
- `BitwardenShared/UI/<Domain>/<Feature>/<Feature>Coordinator.swift`
- `BitwardenShared/UI/<Domain>/<Feature>/<Feature>Processor.swift`
- `BitwardenShared/UI/<Domain>/<Feature>/<Feature>State.swift`
- `BitwardenShared/UI/<Domain>/<Feature>/<Feature>Action.swift`
- `BitwardenShared/UI/<Domain>/<Feature>/<Feature>Effect.swift`
- `BitwardenShared/UI/<Domain>/<Feature>/<Feature>View.swift`

#### Tests (co-located with implementation)
- `BitwardenShared/UI/<Domain>/<Feature>/<Feature>ProcessorTests.swift`
- `BitwardenShared/Core/<Domain>/<Feature>/Services/<Feature>ServiceTests.swift`

### Modified Files
- `BitwardenShared/Core/Platform/Services/ServiceContainer.swift` — Add new service
- `<Existing>Coordinator.swift` — Add new route
```

## Step 4: Dependency-Ordered Implementation Phases

Order phases so each builds on the previous:

```
### Phase 1: Data / Core Layer
Models, CoreData entities (if needed), service protocols, repository protocols

### Phase 2: Service/Repository Implementations
Default<Name>Service/Repository — business logic, SDK calls, network

### Phase 3: DI Wiring
ServiceContainer extensions, Has* protocol additions

### Phase 4: Processor + State
StateProcessor subclass, State struct, Action enum, Effect enum

### Phase 5: View + Coordinator
SwiftUI View with store.binding, Coordinator with routes, navigation wiring

### Phase 6: Tests
ProcessorTests (action/effect paths), ServiceTests (business logic), ViewTests (snapshots if UI)
```

## Step 5: Risk Assessment

Identify risks and mitigations:
- **Security**: Does this touch vault data, auth tokens, or Keychain? → Security review required
- **Extensions**: Does this affect AutoFill/Action/Share extensions? → Memory limit check needed
- **Multi-account**: Does this need per-account isolation? → CoreData userId scoping
- **SDK dependency**: Does this require BitwardenSdk changes? → Coordinate with SDK team

## Step 6: Save Design Document

Save the plan to `.claude/outputs/plans/<ticket-id>.md`.

## Confirm Before Proceeding

Present the plan to the user and ask: "Here is the implementation plan. Should I proceed with implementation?"
