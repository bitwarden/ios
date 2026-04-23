// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
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
    func test_enabledState_showsEnabledMessage() throws {
        processor.state.extensionEnabled = true

        XCTAssertNoThrow(try subject.inspect().find(text: "Safari extension is enabled on this device."))
        XCTAssertThrowsError(try subject.inspect().find(button: "Activate Safari Extension"))
    }

    @MainActor
    func test_activatedState_showsContinueSetupMessage() throws {
        processor.state.extensionActivated = true

        XCTAssertNoThrow(try subject.inspect().find(text: "Finish enabling the Safari extension in Safari settings."))
    }
}
