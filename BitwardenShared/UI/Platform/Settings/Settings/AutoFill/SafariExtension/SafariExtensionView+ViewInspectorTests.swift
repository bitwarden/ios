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
        XCTAssertNoThrow(try subject.inspect().find(text: "Bitwarden already opened the Safari setup flow. Reopen it if you still need to finish turning on the extension in Safari."))
        XCTAssertThrowsError(try subject.inspect().find(button: "Activate Safari Extension"))
        XCTAssertThrowsError(try subject.inspect().find(button: "Open Safari Settings"))
    }

    @MainActor
    func test_enabledState_showsEnabledMessage() throws {
        processor.state.extensionEnabled = true

        XCTAssertNoThrow(try subject.inspect().find(text: "Safari extension is enabled on this device."))
        XCTAssertThrowsError(try subject.inspect().find(text: "Starts the Safari setup flow from Bitwarden."))
        XCTAssertThrowsError(try subject.inspect().find(text: "Reopen the setup flow, then finish turning on Bitwarden in Safari."))
        XCTAssertThrowsError(try subject.inspect().find(button: "Activate Safari Extension"))
    }

    @MainActor
    func test_activatedState_showsContinueSetupMessage() throws {
        processor.state.extensionActivated = true

        XCTAssertNoThrow(try subject.inspect().find(text: "Finish setup in Safari"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Continue setup"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Bitwarden opened the Safari setup flow. Finish turning on the extension in Safari."))
        XCTAssertNoThrow(try subject.inspect().find(text: "Step 2 of 2"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Almost done"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Status"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Progress"))
        XCTAssertNoThrow(try subject.inspect().find(text: "What you can do"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Setup checklist"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Next step"))
        XCTAssertNoThrow(try subject.inspect().find(viewWithAccessibilityIdentifier: "SafariExtensionNextStepBadge"))
        XCTAssertNoThrow(try subject.inspect().find(viewWithAccessibilityIdentifier: "SafariExtensionNextStepIconContinue"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Needs action"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Turn on in Safari"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Now"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Open the setup sheet again"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Then"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Turn on Bitwarden for Safari"))
        let summaryTexts = try subject.inspect().findAll(ViewType.Text.self)
            .compactMap { try? $0.string() }
        XCTAssertEqual(summaryTexts.filter { $0 == "Step 2 of 2" }.count, 1)
        XCTAssertEqual(summaryTexts.filter { $0 == "Almost done" }.count, 1)
        XCTAssertNoThrow(try subject.inspect().find(text: "Safari setup was already opened from Bitwarden. Reopen it if needed, then turn on Bitwarden for Safari."))
        XCTAssertThrowsError(try subject.inspect().find(text: "Not enabled"))
        XCTAssertThrowsError(try subject.inspect().find(text: "Get started"))
        XCTAssertThrowsError(try subject.inspect().find(text: "You’re ready"))
        XCTAssertThrowsError(try subject.inspect().find(text: "Activate Bitwarden, then allow it in Safari settings."))
    }

    @MainActor
    func test_defaultState_showsStepOneAndStatusLabel() throws {
        XCTAssertNoThrow(try subject.inspect().find(text: "Set up Bitwarden for Safari"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Set up now"))
        XCTAssertNoThrow(try subject.inspect().find(button: "Activate Safari Extension"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Starts the Safari setup flow from Bitwarden."))
        XCTAssertNoThrow(try subject.inspect().find(text: "Step 1 of 2"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Not enabled"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Status"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Progress"))
        XCTAssertNoThrow(try subject.inspect().find(text: "What you can do"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Setup checklist"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Next step"))
        XCTAssertNoThrow(try subject.inspect().find(viewWithAccessibilityIdentifier: "SafariExtensionNextStepBadge"))
        XCTAssertNoThrow(try subject.inspect().find(viewWithAccessibilityIdentifier: "SafariExtensionNextStepIconStart"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Start here"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Activate in Bitwarden"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Start the Safari setup flow in Bitwarden, then turn on the extension in Safari."))
        XCTAssertNoThrow(try subject.inspect().find(text: "Now"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Start setup from Bitwarden"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Then"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Allow Bitwarden in Safari"))
        XCTAssertThrowsError(try subject.inspect().find(text: "Get started"))
        let summaryTexts = try subject.inspect().findAll(ViewType.Text.self)
            .compactMap { try? $0.string() }
        XCTAssertEqual(summaryTexts.filter { $0 == "Step 1 of 2" }.count, 1)
        XCTAssertEqual(summaryTexts.filter { $0 == "Not enabled" }.count, 1)
        XCTAssertNoThrow(try subject.inspect().find(text: "Activate in Bitwarden"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Start the Safari setup flow from Bitwarden."))
        XCTAssertNoThrow(try subject.inspect().find(viewWithAccessibilityIdentifier: "SafariExtensionStepOneBadge"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Current step"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Turn on in Safari"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Allow Bitwarden in Safari, then return here."))
        XCTAssertNoThrow(try subject.inspect().find(viewWithAccessibilityIdentifier: "SafariExtensionStepTwoBadge"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Up next"))
        XCTAssertThrowsError(try subject.inspect().find(text: "Done"))
        XCTAssertThrowsError(try subject.inspect().find(text: "Safari setup completed from Bitwarden."))
    }

    @MainActor
    func test_activatedState_showsChecklistProgress() throws {
        processor.state.extensionActivated = true

        XCTAssertNoThrow(try subject.inspect().find(text: "Activate in Bitwarden"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Safari setup was opened from Bitwarden."))
        XCTAssertNoThrow(try subject.inspect().find(viewWithAccessibilityIdentifier: "SafariExtensionStepOneBadge"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Turn on in Safari"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Turn on Bitwarden in Safari to finish setup."))
        XCTAssertNoThrow(try subject.inspect().find(viewWithAccessibilityIdentifier: "SafariExtensionStepTwoBadge"))
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
        XCTAssertNoThrow(try subject.inspect().find(text: "Ready"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Enabled"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Status"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Progress"))
        XCTAssertNoThrow(try subject.inspect().find(text: "What you can do"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Setup checklist"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Next step"))
        XCTAssertNoThrow(try subject.inspect().find(viewWithAccessibilityIdentifier: "SafariExtensionNextStepBadge"))
        XCTAssertNoThrow(try subject.inspect().find(viewWithAccessibilityIdentifier: "SafariExtensionNextStepIconReady"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Complete"))
        XCTAssertNoThrow(try subject.inspect().find(text: "You’re ready"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Safari setup completed from Bitwarden."))
        XCTAssertNoThrow(try subject.inspect().find(text: "Available now"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Fill and save from Safari pages"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Also included"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Generate passwords without leaving Safari"))
        XCTAssertNoThrow(try subject.inspect().find(viewWithAccessibilityIdentifier: "SafariExtensionStepOneBadge"))
        XCTAssertNoThrow(try subject.inspect().find(text: "Bitwarden is on and ready in Safari."))
        XCTAssertNoThrow(try subject.inspect().find(viewWithAccessibilityIdentifier: "SafariExtensionStepTwoBadge"))
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
