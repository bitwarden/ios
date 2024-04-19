import SnapshotTesting
import XCTest

// MARK: - SettingsViewTests

@testable import AuthenticatorShared

class SettingsViewTests: AuthenticatorTestCase {
    // MARK: Properties

    var processor: MockProcessor<SettingsState, SettingsAction, SettingsEffect>!
    var subject: SettingsView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: SettingsState())
        let store = Store(processor: processor)

        subject = SettingsView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tests the view renders correctly.
    func test_viewRender() {
        assertSnapshot(of: subject, as: .defaultPortrait)
    }
}
