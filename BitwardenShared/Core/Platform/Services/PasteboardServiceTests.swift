import XCTest

@testable import BitwardenShared

class PasteboardServiceTests: BitwardenTestCase {
    // MARK: Properties

    var errorReporter: MockErrorReporter!
    var pasteboard: UIPasteboard!
    var stateService: MockStateService!
    var subject: PasteboardService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        errorReporter = MockErrorReporter()
        pasteboard = UIPasteboard.withUniqueName()
        stateService = MockStateService()
        stateService.activeAccount = .fixture()
        stateService.clearClipboardValues["1"] = .oneMinute

        subject = DefaultPasteboardService(
            errorReporter: errorReporter,
            pasteboard: pasteboard,
            stateService: stateService
        )

        // Wait for the `DefaultPasteboardService.init` task to set the initial clear clipboard
        // value for the active account, otherwise there's a potential race condition between that
        // and the tests below.
        waitFor { subject.clearClipboardValue == .oneMinute }
    }

    override func tearDown() {
        super.tearDown()

        errorReporter = nil
        pasteboard = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// Test that copying a string puts the value on the `UIPasteboard` as expected.
    @MainActor
    func test_copy() async throws {
        try await stateService.setClearClipboardValue(.never)
        subject.copy("Test string")
        XCTAssertEqual(pasteboard.strings?.last, "Test string")
        XCTAssertTrue(pasteboard.isPersistent)

        subject.updateClearClipboardValue(.fiveMinutes)
        waitFor { self.stateService.clearClipboardValues["1"] != .never }
        let value = try await stateService.getClearClipboardValue()
        XCTAssertEqual(value, .fiveMinutes)

        subject.copy("Test string2")
        XCTAssertEqual(pasteboard.strings?.last, "Test string2")
        XCTAssertTrue(pasteboard.isPersistent)
    }

    /// Test that an error from no account should use the default value without recording an error.
    @MainActor
    func test_error_noAccount() async throws {
        stateService.activeAccount = nil

        stateService.activeIdSubject.send(nil)

        waitFor { subject.clearClipboardValue == .never }
        XCTAssertEqual(subject.clearClipboardValue, .never)
        XCTAssertTrue(errorReporter.errors.isEmpty)
    }

    /// Test that an error updating besides not being logged in should be recorded.
    @MainActor
    func test_error_other() async throws {
        stateService.clearClipboardResult = .failure(BitwardenTestError.example)

        stateService.activeIdSubject.send(nil)

        waitFor { self.errorReporter.errors.isEmpty == false }
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// Test that any errors from updating the value are recorded.
    @MainActor
    func test_error_updating() async throws {
        stateService.clearClipboardResult = .failure(BitwardenTestError.example)

        subject.updateClearClipboardValue(.twentySeconds)

        waitFor { self.errorReporter.errors.isEmpty == false }
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }
}
