// swiftlint:disable:this file_name
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenKit

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
                        isEnabled: false,
                    ),
                ],
            ),
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

    /// Check the snapshot when feature flags are enabled and disabled.
    @MainActor
    func disabletest_snapshot_debugMenuWithFeatureFlags() {
        processor.state.featureFlags = [
            .init(feature: .testFeatureFlag, isEnabled: true),
        ]
        assertSnapshot(
            of: subject,
            as: .defaultPortrait,
        )
    }
}
