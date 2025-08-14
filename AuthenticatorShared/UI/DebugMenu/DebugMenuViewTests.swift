import BitwardenKit
import BitwardenResources
import SnapshotTesting
import XCTest

@testable import AuthenticatorShared

// MARK: - DebugMenuViewTests

class DebugMenuViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<DebugMenuState, DebugMenuAction, DebugMenuEffect>!
    var subject: DebugMenuView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(
            state: DebugMenuState(
                featureFlags: [
                    .init(
                        feature: .testFeatureFlag,
                        isEnabled: false
                    ),
                ]
            )
        )
        let store = Store(processor: processor)

        subject = DebugMenuView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the close button dispatches the `.dismissTapped` action.
    @MainActor
    func test_closeButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.close)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismissTapped)
    }

    /// Tests that the toggle fires off the correct effect.
    @MainActor
    func test_featureFlag_toggled() async throws {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            throw XCTSkip("Unable to run test in iOS 16, keep an eye on ViewInspector to see if it gets updated.")
        }
        let featureFlagName = FeatureFlag.testFeatureFlag.rawValue
        let toggle = try subject.inspect().find(viewWithAccessibilityIdentifier: featureFlagName).toggle()
        try toggle.tap()
        XCTAssertEqual(processor.effects.last, .toggleFeatureFlag(featureFlagName, true))
    }

    /// Test that the refresh button sends the correct effect.
    @MainActor
    func test_refreshFeatureFlags_tapped() async throws {
        let button = try subject.inspect().find(asyncButtonWithAccessibilityLabel: "RefreshFeatureFlagsButton")
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .refreshFeatureFlags)
    }

    /// Check the snapshot when feature flags are enabled and disabled.
    @MainActor
    func test_snapshot_debugMenuWithFeatureFlags() {
        processor.state.featureFlags = [
            .init(
                feature: .testFeatureFlag,
                isEnabled: true
            ),
        ]
        assertSnapshot(of: subject, as: .defaultPortrait)
    }
}
