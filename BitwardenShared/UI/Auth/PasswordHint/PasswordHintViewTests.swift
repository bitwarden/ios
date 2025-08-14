import BitwardenResources
import SnapshotTesting
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - PasswordHintViewTests

class PasswordHintViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<PasswordHintState, PasswordHintAction, PasswordHintEffect>!
    var subject: PasswordHintView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        let state = PasswordHintState()
        processor = MockProcessor(state: state)
        subject = PasswordHintView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping on the dismiss button dispatches the `.dismissPressed` action.
    @MainActor
    func test_dismissButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.cancel)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismissPressed)
    }

    /// Editing the text in the email address text field dispatches the `.emailAddressChanged`
    /// action.
    @MainActor
    func test_emailAddress_change() throws {
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.emailAddress)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .emailAddressChanged("text"))
    }

    /// Tapping on the submit button performs the `.submitPressed` effect.
    @MainActor
    func test_submitButton_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.submit)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .submitPressed)
    }

    // MARK: Snapshots

    /// A snapshot of the view without any values set.
    @MainActor
    func test_snapshot_empty() {
        processor.state.emailAddress = ""
        assertSnapshot(of: subject.navStackWrapped, as: .defaultPortrait)
    }

    /// A snapshot of the view with a value in the email address field.
    @MainActor
    func test_snapshot_withEmailAddress() {
        processor.state.emailAddress = "email@example.com"
        assertSnapshots(of: subject.navStackWrapped, as: [.defaultPortrait, .defaultPortraitAX5, .defaultPortraitDark])
    }
}
