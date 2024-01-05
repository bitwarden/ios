import XCTest

@testable import BitwardenShared

class PasteboardServiceTests: BitwardenTestCase {
    // MARK: Properties

    var errorReporter: MockErrorReporter!
    var stateService: MockStateService!
    var subject: PasteboardService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        errorReporter = MockErrorReporter()

        stateService = MockStateService()
        stateService.activeAccount = .fixture()

        subject = DefaultPasteboardService(
            errorReporter: errorReporter,
            stateService: stateService
        )
    }

    override func tearDown() {
        super.tearDown()

        errorReporter = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// Test that copying a string puts the value on the `UIPasteboard` as expected.
    func test_copy() async throws {
        try await stateService.setClearClipboardValue(.never)
        subject.copy("Test string")
        XCTAssertEqual(UIPasteboard.general.strings?.last, "Test string")
        XCTAssertTrue(UIPasteboard.general.isPersistent)

        subject.updateClearClipboardValue(.fiveMinutes)
        waitFor { self.stateService.clearClipboardValues["1"] != .never }
        let value = try await stateService.getClearClipboardValue()
        XCTAssertEqual(value, .fiveMinutes)

        subject.copy("Test string2")
        XCTAssertEqual(UIPasteboard.general.strings?.last, "Test string2")
        XCTAssertTrue(UIPasteboard.general.isPersistent)
    }

    /// Test that an error from no account should use the default value without recording an error.
    func test_error_noAccount() async throws {
        stateService.activeAccount = nil

        stateService.activeIdSubject.send(nil)

        XCTAssertEqual(subject.clearClipboardValue, .never)
        XCTAssertTrue(errorReporter.errors.isEmpty)
    }

    /// Test that an error updating besides not being logged in should be recorded.
    func test_error_other() async throws {
        stateService.clearClipboardResult = .failure(BitwardenTestError.example)

        stateService.activeIdSubject.send(nil)

        waitFor { self.errorReporter.errors.isEmpty == false }
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// Test that any errors from updating the value are recorded.
    func test_error_updating() async throws {
        stateService.clearClipboardResult = .failure(BitwardenTestError.example)

        subject.updateClearClipboardValue(.twentySeconds)

        waitFor { self.errorReporter.errors.isEmpty == false }
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }
}
