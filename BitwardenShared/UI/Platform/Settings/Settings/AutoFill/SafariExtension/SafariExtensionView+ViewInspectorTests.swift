// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import ViewInspector
import XCTest

@testable import BitwardenShared

class SafariExtensionViewTests: BitwardenTestCase {
    var processor: MockProcessor<SafariExtensionState, SafariExtensionAction, Void>!
    var subject: SafariExtensionView!

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: SafariExtensionState())
        subject = SafariExtensionView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    @MainActor
    func test_activateButton_tap() throws {
        let button = try subject.inspect().find(button: "Activate Safari Extension")
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .activateButtonTapped)
    }

    @MainActor
    func test_activatedState_showsContinueSafariSetupButton() throws {
        processor.state.extensionActivated = true

        XCTAssertNoThrow(try subject.inspect().find(button: "Continue Safari Setup"))
        XCTAssertThrowsError(try subject.inspect().find(button: "Activate Safari Extension"))
        XCTAssertThrowsError(try subject.inspect().find(button: "Open Safari Settings"))
    }

    @MainActor
    func test_enabledState_showsEnabledMessage() throws {
        processor.state.extensionEnabled = true

        XCTAssertNoThrow(try subject.inspect().find(text: "Safari extension is enabled on this device."))
        XCTAssertThrowsError(try subject.inspect().find(button: "Activate Safari Extension"))
    }

    @MainActor
    func test_activatedState_showsContinueSetupMessage() throws {
        processor.state.extensionActivated = true

        XCTAssertNoThrow(try subject.inspect().find(text: "Finish enabling the Safari extension in Safari settings."))
        XCTAssertNoThrow(try subject.inspect().find(text: "Step 2 of 2"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Almost done"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Finish setup"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Open Safari settings and turn on Bitwarden for Safari."))
        XCTAssertThrowsError(try subject.inspect().find(text: "Not enabled"))
        XCTAssertThrowsError(try subject.inspect().find(text: "Get started"))
        XCTAssertThrowsError(try subject.inspect().find(text: "You’re ready"))
        XCTAssertThrowsError(try subject.inspect().find(text: "Activate Bitwarden, then allow it in Safari settings."))
    }

    @MainActor
    func test_defaultState_showsStepOneAndStatusLabel() throws {
        XCTAssertNoThrow(try subject.inspect().find(text: "Step 1 of 2"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Not enabled"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Get started"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Activate Bitwarden, then allow it in Safari settings."))
        XCTAssertNoThrow(try subject.inspect().find(text: "Activate in Bitwarden"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Current step"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Turn on in Safari Settings"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Up next"))
        XCTAssertThrowsError(try subject.inspect().find(text: "Done"))
    }

    @MainActor
    func test_activatedState_showsChecklistProgress() throws {
        processor.state.extensionActivated = true

        XCTAssertNoThrow(try subject.inspect().find(text: "Activate in Bitwarden"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Turn on in Safari Settings"))
        let doneTexts = try subject.inspect().findAll(ViewType.Text.self)
            .compactMap { try? $0.string() }
            .filter { $0 == "Done" }
        XCTAssertEqual(doneTexts.count, 1)
        XCTAssertNoThrow(try subject.inspect().find(text: "Current step"))
        XCTAssertThrowsError(try subject.inspect().find(text: "Up next"))
    }

    @MainActor
    func test_enabledState_showsEnabledStatusLabel() throws {
        processor.state.extensionEnabled = true

        XCTAssertNoThrow(try subject.inspect().find(text: "Enabled"))
        XCTAssertNoThrow(try subject.inspect().find(text: "You’re ready"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Ready to fill, save, update, and generate credentials in Safari."))
        XCTAssertThrowsError(try subject.inspect().find(text: "Finish setup"))
        let doneTexts = try subject.inspect().findAll(ViewType.Text.self)
            .compactMap { try? $0.string() }
            .filter { $0 == "Done" }
        XCTAssertEqual(doneTexts.count, 2)
        XCTAssertThrowsError(try subject.inspect().find(text: "Current step"))
        XCTAssertThrowsError(try subject.inspect().find(text: "Up next"))
    }
}
