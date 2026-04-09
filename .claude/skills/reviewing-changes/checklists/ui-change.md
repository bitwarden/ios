# UI Change Review Checklist

Use for: Changes only to `*View.swift` files with no business logic changes. New SwiftUI components, layout adjustments, accessibility improvements.

## Focus Areas

UI change reviews are **design-focused** — verify UDF compliance, accessibility, and component reuse. Skip deep architecture review unless business logic has crept into the view.

## Checklist

**1. UDF Compliance:**
- No business logic in the view
- State mutations go through `store.send(action)` or `await store.perform(effect)`
- All SwiftUI bindings use `store.binding(get:send:)` — no `@State` for store-backed data
- No direct service calls from the view

**2. Component Reuse:**
- Existing components from `BitwardenKit/UI/` used where applicable before creating custom ones
- New reusable components placed in `BitwardenKit/UI/` (not buried in feature folder)

**3. Accessibility:**
- Interactive elements have accessibility labels (`.accessibilityLabel`, `.accessibilityHint`)
- Dynamic Type supported — no hardcoded font sizes, uses `Localizations` or system fonts
- Color is not the only visual indicator of state

**4. Snapshot Tests:**
- New/modified views have snapshot tests in three modes:
  - `.defaultPortrait` (light mode)
  - `.defaultPortraitDark` (dark mode)
  - `.defaultPortraitAX5` (large dynamic type)
- Snapshot test functions prefixed with `disabletest_` (snapshots currently disabled globally)
- Simulator matches `.test-simulator-device-name` and `.test-simulator-ios-version`

**5. Style:**
- Uses `Localizations` for all user-facing strings — no hardcoded strings
- Module imports correct (`BitwardenResources` for assets/localizations, `BitwardenKit` for components)

## Prioritizing Findings

See `reference/priority-framework.md`. For UI changes:
- **Critical**: UDF violated (business logic in view, direct state mutation)
- **Important**: Missing accessibility for interactive elements; missing snapshot tests
- **Suggested**: Minor layout/spacing improvements

## Output Format

See `examples/annotated-example.md` for the required output format and inline comment structure.
