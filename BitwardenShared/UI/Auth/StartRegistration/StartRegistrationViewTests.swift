import BitwardenResources
import SnapshotTesting
import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - StartRegistrationViewTests

class StartRegistrationViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<StartRegistrationState, StartRegistrationAction, StartRegistrationEffect>!
    var subject: StartRegistrationView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(state: StartRegistrationState())
        let store = Store(processor: processor)
        subject = StartRegistrationView(store: store)
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the cancel button dispatches the `.dismiss` action.
    @MainActor
    func test_cancelButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.cancel)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismiss)
    }

    /// Updating the text field dispatches the `.emailTextChanged()` action.
    @MainActor
    func test_emailField_updateValue() throws {
        let textfield = try subject.inspect().find(viewWithId: Localizations.emailAddress).textField()
        try textfield.setInput("text")
        XCTAssertEqual(processor.dispatchedActions.last, .emailTextChanged("text"))
    }

    /// Updating the text field dispatches the `.nameTextChanged()` action.
    @MainActor
    func test_nameField_updateValue() throws {
        let textfield = try subject.inspect().find(viewWithId: Localizations.name).textField()
        try textfield.setInput("user name")
        XCTAssertEqual(processor.dispatchedActions.last, .nameTextChanged("user name"))
    }

    /// Tapping the continue button performs the `.StartRegistration` effect.
    @MainActor
    func test_continueButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.continue)
        try button.tap()

        waitFor(!processor.effects.isEmpty)

        XCTAssertEqual(processor.effects.last, .startRegistration)
    }

    /// Tapping the region button dispatches the `.regionPressed` action.
    @MainActor
    func test_regionButton_tap() throws {
        let button = try subject.inspect().find(
            button: "\(Localizations.creatingOn): \(subject.store.state.region.baseURLDescription)"
        )
        try button.tap()
        waitFor(!processor.effects.isEmpty)
        XCTAssertEqual(processor.effects.last, .regionTapped)
    }

    /// Tapping the receive marketing toggle dispatches the `.toggleReceiveMarketing()` action.
    @MainActor
    func test_receiveMarketingToggle_tap() throws {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            throw XCTSkip("Unable to run test in iOS 16, keep an eye on ViewInspector to see if it gets updated.")
        }
        let toggle = try subject.inspect().find(viewWithId: ViewIdentifier.StartRegistration.receiveMarketing).toggle()
        try toggle.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .toggleReceiveMarketing(true))
    }

    // MARK: Snapshots

    /// Tests the view renders correctly when the text fields are all empty.
    @MainActor
    func test_snapshot_empty() {
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark])
    }

    /// Tests the view renders correctly when the text fields are all populated.
    @MainActor
    func test_snapshot_textFields_populated() throws {
        processor.state.emailText = "email@example.com"
        processor.state.nameText = "user name"

        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// Tests the view renders correctly when the text fields are all populated with long text.
    @MainActor
    func test_snapshot_textFields_populated_long() throws {
        processor.state.emailText = "emailmmmmmmmmmmmmmmmmmmmmm@exammmmmmmmmmmmmmmmmmmmmmmmmmmmmmmple.com"
        processor.state.nameText = "user name name name name name name name name name name name name name name"

        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// Tests the view renders correctly when the toggles are on.
    @MainActor
    func test_snapshot_toggles_on() throws {
        processor.state.isReceiveMarketingToggleOn = true

        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// Tests the view renders correctly when the marketing toggle is hidden.
    @MainActor
    func test_snapshot_marketingToggle_hidden() throws {
        processor.state.showReceiveMarketingToggle = false

        assertSnapshot(of: subject, as: .defaultPortrait)
    }
}
