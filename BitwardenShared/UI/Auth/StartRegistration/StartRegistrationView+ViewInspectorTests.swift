// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
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
        let button = try subject.inspect().findCancelToolbarButton()
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
            button: "\(Localizations.creatingOn): \(subject.store.state.region.baseURLDescription)",
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
}
