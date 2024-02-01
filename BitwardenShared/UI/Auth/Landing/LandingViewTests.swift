import SnapshotTesting
import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - LandingViewTests

class LandingViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<LandingState, LandingAction, LandingEffect>!
    var subject: LandingView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(state: LandingState())
        let store = Store(processor: processor)
        subject = LandingView(store: store)
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// The continue button should be disabled when there is no value in the email field.
    func test_continueButton_disabled() throws {
        processor.state.email = ""
        let button = try subject.inspect().find(button: Localizations.continue)
        XCTAssertTrue(button.isDisabled())
    }

    /// The continue button should be enabled when there is a value in the email field.
    func test_continueButton_enabled() throws {
        processor.state.email = "email@example.com"
        let button = try subject.inspect().find(button: Localizations.continue)
        XCTAssertFalse(button.isDisabled())
    }

    /// Tapping the continue button dispatches the `.continuePressed` action.
    func test_continueButton_tap() throws {
        processor.state.email = "email@example.com"
        let button = try subject.inspect().find(button: Localizations.continue)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .continuePressed)
    }

    /// Tapping the create account button dispatches the `.createAccountPressed` action.
    func test_createAccountButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.createAccount)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .createAccountPressed)
    }

    /// Updating the text field dispatches the `.emailChanged()` action.
    func test_emailAddressTextField_updateValue() throws {
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.emailAddress)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .emailChanged("text"))
    }

    /// Tapping the region button dispatches the `.regionPressed` action.
    func test_regionButton_tap() throws {
        let button = try subject.inspect().find(
            button: "\(Localizations.loggingInOn): \(RegionType.unitedStates.baseUrlDescription)"
        )
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .regionPressed)
    }

    /// Tapping the remember me toggle dispatches the `.rememberMeChanged` action.
    func test_rememberMeToggle_tap() throws {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            throw XCTSkip("Unable to run test in iOS 16, keep an eye on ViewInspector to see if it gets updated.")
        }
        let toggle = try subject.inspect().find(ViewType.Toggle.self)
        try toggle.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .rememberMeChanged(true))
    }

    // MARK: Snapshots

    /// Check the snapshot for the empty state.
    func test_snapshot_empty() {
        assertSnapshot(matching: subject, as: .defaultPortrait)
    }

    /// Check the snapshot when the email text field has a value.
    func test_snapshot_email_value() {
        processor.state.email = "email@example.com"
        assertSnapshot(matching: subject, as: .defaultPortrait)
    }

    /// Check the snapshot when the remember me toggle is on.
    func test_snapshot_isRememberMeOn_true() {
        processor.state.isRememberMeOn = true
        assertSnapshot(matching: subject, as: .defaultPortrait)
    }

    /// Check the snapshot for the profiles visible
    func test_snapshot_profilesVisible() {
        let account = ProfileSwitcherItem.fixture(
            email: "extra.warden@bitwarden.com",
            userInitials: "EW"
        )
        processor.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [
                account,
            ],
            activeAccountId: account.userId,
            isVisible: true
        )
        assertSnapshot(matching: subject, as: .defaultPortrait)
    }

    /// Check the snapshot for the profiles closed
    func test_snapshot_profilesClosed() {
        let account = ProfileSwitcherItem.fixture(
            email: "extra.warden@bitwarden.com",
            userInitials: "EW"
        )
        processor.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [
                account,
            ],
            activeAccountId: account.userId,
            isVisible: false
        )
        assertSnapshot(matching: subject, as: .defaultPortrait)
    }
}
