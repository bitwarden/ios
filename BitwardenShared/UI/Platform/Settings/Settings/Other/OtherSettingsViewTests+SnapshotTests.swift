import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

class OtherSettingsViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<OtherSettingsState, OtherSettingsAction, OtherSettingsEffect>!
    var subject: OtherSettingsView!

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: OtherSettingsState())

        subject = OtherSettingsView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// The view renders correctly.
    @MainActor
    func disabletest_view_render() {
        processor.state.lastSyncDate = Date(year: 2023, month: 5, day: 14, hour: 16, minute: 52)
        processor.state.shouldShowConnectToWatchToggle = true
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }
}
