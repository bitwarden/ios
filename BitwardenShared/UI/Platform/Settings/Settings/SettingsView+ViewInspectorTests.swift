// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import XCTest

// MARK: - SettingsViewTests

@testable import BitwardenShared

class SettingsViewTests: BitwardenTestCase {
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
    @MainActor
    func test_aboutButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.about)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .aboutPressed)
    }

    /// Tapping the accountSecurity button dispatches the `.accountSecurityPressed` action.
    @MainActor
    func test_accountSecurityButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.accountSecurity)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .accountSecurityPressed)
    }

    /// Tapping the appearance button dispatches the `.appearancePressed` action.
    @MainActor
    func test_appearanceButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.appearance)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .appearancePressed)
    }

    /// Tapping the autofill button dispatches the `.autoFillPressed` action.
    @MainActor
    func test_autofillButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.autofill)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .autoFillPressed)
    }

    /// Tapping the close button dispatches the `.dismiss` action.
    @MainActor
    func test_close_tap() throws {
        processor.state.presentationMode = .preLogin
        let button = try subject.inspect().findCloseToolbarButton()
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismiss)
    }

    /// Tapping the other button dispatches the `.otherPressed` action.
    @MainActor
    func test_otherButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.other)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .otherPressed)
    }

    /// Tapping the vault button dispatches the `.vaultPressed` action.
    @MainActor
    func test_vaultButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.vault)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .vaultPressed)
    }
}
