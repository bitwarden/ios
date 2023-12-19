import SnapshotTesting
import XCTest

@testable import BitwardenShared

class OtherSettingsViewTests: BitwardenTestCase {
    // MARK: Properties

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
    func test_syncNow_tapped() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.syncNow)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .syncNow)
    }

    /// The view renders correctly.
    func test_view_render() {
        assertSnapshot(of: subject, as: .defaultPortrait)
    }
}
