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

        XCTAssertNoThrow(try subject.inspect().find(text: "Finish setup in Safari"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Continue the Safari setup flow to finish enabling the extension."))
        XCTAssertNoThrow(try subject.inspect().find(text: "Step 2 of 2"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Almost done"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Status"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Progress"))
        XCTAssertNoThrow(try subject.inspect().find(text: "What you can do"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Setup checklist"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Next step"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Turn on in Safari"))
        let summaryTexts = try subject.inspect().findAll(ViewType.Text.self)
            .compactMap { try? $0.string() }
        XCTAssertEqual(summaryTexts.filter { $0 == "Step 2 of 2" }.count, 1)
        XCTAssertEqual(summaryTexts.filter { $0 == "Almost done" }.count, 1)
        XCTAssertNoThrow(try subject.inspect().find(text: "Open the Safari setup sheet again, then turn on Bitwarden for Safari."))
        XCTAssertThrowsError(try subject.inspect().find(text: "Not enabled"))
        XCTAssertThrowsError(try subject.inspect().find(text: "Get started"))
        XCTAssertThrowsError(try subject.inspect().find(text: "You’re ready"))
        XCTAssertThrowsError(try subject.inspect().find(text: "Activate Bitwarden, then allow it in Safari settings."))
    }

    @MainActor
    func test_defaultState_showsStepOneAndStatusLabel() throws {
        XCTAssertNoThrow(try subject.inspect().find(text: "Set up Bitwarden for Safari"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Step 1 of 2"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Not enabled"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Status"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Progress"))
        XCTAssertNoThrow(try subject.inspect().find(text: "What you can do"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Setup checklist"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Next step"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Activate in Bitwarden"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Start the Safari setup flow in Bitwarden, then turn on the extension in Safari."))
        XCTAssertThrowsError(try subject.inspect().find(text: "Get started"))
        let summaryTexts = try subject.inspect().findAll(ViewType.Text.self)
            .compactMap { try? $0.string() }
        XCTAssertEqual(summaryTexts.filter { $0 == "Step 1 of 2" }.count, 1)
        XCTAssertEqual(summaryTexts.filter { $0 == "Not enabled" }.count, 1)
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

        XCTAssertNoThrow(try subject.inspect().find(text: "Bitwarden is ready in Safari"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Enabled"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Status"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Progress"))
        XCTAssertNoThrow(try subject.inspect().find(text: "What you can do"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Setup checklist"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Next step"))
        XCTAssertNoThrow(try subject.inspect().find(text: "You’re ready"))
        let summaryTexts = try subject.inspect().findAll(ViewType.Text.self)
            .compactMap { try? $0.string() }
        XCTAssertEqual(summaryTexts.filter { $0 == "Step 2 of 2" }.count, 1)
        XCTAssertEqual(summaryTexts.filter { $0 == "Enabled" }.count, 1)
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
