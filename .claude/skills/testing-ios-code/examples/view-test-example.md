# View Test Example

Based on: `BitwardenShared/UI/Auth/Landing/LandingView+ViewInspectorTests.swift`
and: `BitwardenShared/UI/Auth/Landing/LandingView+SnapshotTests.swift`

## ViewInspector Tests (Interactions)

```swift
// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - FeatureViewTests

class FeatureViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<FeatureState, FeatureAction, FeatureEffect>!
    var subject: FeatureView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: FeatureState())
        let store = Store(processor: processor)
        subject = FeatureView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping a button dispatches the expected Action (sync).
    @MainActor
    func test_someButton_tap_dispatchesAction() throws {
        let button = try subject.inspect().find(button: Localizations.someLabel)
        try button.tap()

        XCTAssertEqual(processor.dispatchedActions.last, .someButtonTapped)
    }

    /// Tapping an async button dispatches the expected Effect.
    @MainActor
    func test_continueButton_tap_dispatchesEffect() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.continue)
        try await button.tap()

        XCTAssertEqual(processor.effects.last, .continuePressed)
    }

    /// A button is disabled when state has no value.
    @MainActor
    func test_continueButton_disabled_whenEmailEmpty() throws {
        processor.state.email = ""
        let button = try subject.inspect().find(button: Localizations.continue)

        XCTAssertTrue(button.isDisabled())
    }

    /// A button is enabled when state has a value.
    @MainActor
    func test_continueButton_enabled_whenEmailPopulated() throws {
        processor.state.email = "user@example.com"
        let button = try subject.inspect().find(button: Localizations.continue)

        XCTAssertFalse(button.isDisabled())
    }
}
```

## Snapshot Tests

```swift
// MARK: - FeatureViewTests (Snapshot)
// Note: snapshot test functions are prefixed with `disabletest_` — snapshots globally disabled.

class FeatureViewTests: BitwardenTestCase {
    var processor: MockProcessor<FeatureState, FeatureAction, FeatureEffect>!
    var subject: FeatureView!

    override func setUp() {
        super.setUp()
        processor = MockProcessor(state: FeatureState())
        subject = FeatureView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    @MainActor
    func disabletest_snapshot_default() {
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    @MainActor
    func disabletest_snapshot_populated() {
        processor.state.email = "user@example.com"
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }
}
```

## Key Patterns

- `MockProcessor<State, Action, Effect>` — use instead of a real processor
- `Store(processor: processor)` — wrap the mock processor in a Store
- `processor.dispatchedActions.last` — sync actions (sent via `store.send`)
- `processor.effects.last` — async effects (sent via `store.perform`)
- `find(button:)` — sync button; `find(asyncButton:)` — async button
- Snapshot functions prefixed `disabletest_` — three modes: `.defaultPortrait`, `.defaultPortraitDark`, `.defaultPortraitAX5`
