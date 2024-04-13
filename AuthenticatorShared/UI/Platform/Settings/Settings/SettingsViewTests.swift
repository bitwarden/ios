import SnapshotTesting
import XCTest

// MARK: - SettingsViewTests

@testable import AuthenticatorShared

class SettingsViewTests: AuthenticatorTestCase {
    // MARK: Properties

    var processor: MockProcessor<SettingsState, SettingsAction, Void>!
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

    /// Tapping the about button dispatches the `.aboutPressed` action.
    func test_aboutButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.about)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .aboutPressed)
    }

    /// Tapping the appearance button dispatches the `.appearancePressed` action.
    func test_appearanceButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.appearance)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .appearancePressed)
    }

    /// Tests the view renders correctly.
    func test_viewRender() {
        assertSnapshot(of: subject, as: .defaultPortrait)
    }
}
