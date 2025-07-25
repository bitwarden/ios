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

    /// Tapping the sync now button performs the `.syncNow` effect.
    @MainActor
    func test_syncNow_tapped() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.syncNow)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .syncNow)
    }

    /// The connect to watch toggle is hidden if the device is not an iPhone.
    @MainActor
    func test_connectToWatchToggle_hidden() async throws {
        processor.state.shouldShowConnectToWatchToggle = false
        XCTAssertThrowsError(try subject.inspect().find(toggleWithAccessibilityLabel: Localizations.connectToWatch))
    }

    /// The connect to watch toggle is visible if the device is an iPhone.
    @MainActor
    func test_connectToWatchToggle_visible() async throws {
        processor.state.shouldShowConnectToWatchToggle = true
        XCTAssertNoThrow(try subject.inspect().find(toggleWithAccessibilityLabel: Localizations.connectToWatch))
    }

    /// The view renders correctly.
    @MainActor
    func test_view_render() {
        processor.state.lastSyncDate = Date(year: 2023, month: 5, day: 14, hour: 16, minute: 52)
        processor.state.shouldShowConnectToWatchToggle = true
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }
}
