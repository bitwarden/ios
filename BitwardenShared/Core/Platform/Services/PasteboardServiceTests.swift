import BitwardenKit
import BitwardenKitMocks
import TestHelpers
import UIKit
import UniformTypeIdentifiers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

class PasteboardServiceTests: BitwardenTestCase {
    // MARK: Properties

    var errorReporter: MockErrorReporter!
    var pasteboard: MockPasteboard!
    var stateService: MockStateService!
    var subject: DefaultPasteboardSettingsProvider!
    var writer: DefaultPasteboardService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        errorReporter = MockErrorReporter()
        pasteboard = MockPasteboard()
        stateService = MockStateService()
        stateService.activeAccount = .fixture()
        stateService.clearClipboardValues["1"] = .oneMinute
        stateService.allowUniversalClipboard["1"] = false
        subject = DefaultPasteboardSettingsProvider(
            errorReporter: errorReporter,
            stateService: stateService,
        )
        writer = DefaultPasteboardService(pasteboard: pasteboard, settingsProvider: subject)
    }

    override func tearDown() {
        super.tearDown()
        errorReporter = nil
        pasteboard = nil
        stateService = nil
        subject = nil
        writer = nil
    }

    // MARK: Tests

    @MainActor
    func test_copy_appliesBothPreferences() async throws {
        try await waitForInitialization()

        writer.copy("local")
        let copiedText = pasteboard.setItemsReceivedArguments?.items.first?[UTType.utf8PlainText.identifier] as? String
        XCTAssertEqual(copiedText, "local")
        XCTAssertEqual(pasteboard.setItemsReceivedArguments?.options[.localOnly] as? Bool, true)
        XCTAssertNotNil(pasteboard.setItemsReceivedArguments?.options[.expirationDate] as? Date)

        subject.updateAllowUniversalClipboard(true)
        subject.updateClearClipboardValue(.never)
        writer.copy("shared")
        let sharedText = pasteboard.setItemsReceivedArguments?.items.first?[UTType.utf8PlainText.identifier] as? String
        XCTAssertEqual(sharedText, "shared")
        XCTAssertEqual(pasteboard.setItemsReceivedArguments?.options[.localOnly] as? Bool, false)
        XCTAssertNil(pasteboard.setItemsReceivedArguments?.options[.expirationDate])
        XCTAssertEqual(pasteboard.setItemsCallsCount, 2)
    }

    @MainActor
    func test_accountChange_loadsBothPreferences() async throws {
        try await waitForInitialization()
        XCTAssertEqual(subject.clearClipboardValue, .oneMinute)
        XCTAssertFalse(subject.allowUniversalClipboard)

        stateService.clearClipboardValues["2"] = .fiveMinutes
        stateService.allowUniversalClipboard["2"] = true
        stateService.activeAccount = .fixture(profile: .fixture(userId: "2"))
        stateService.activeIdSubject.send("2")

        try await waitForAsync {
            self.subject.clearClipboardValue == .fiveMinutes && self.subject.allowUniversalClipboard
        }
    }

    @MainActor
    func test_error_noAccount() async throws {
        try await waitForInitialization()
        subject.updateAllowUniversalClipboard(true)
        try await waitForAsync { self.stateService.allowUniversalClipboard["1"] == true }
        stateService.activeAccount = nil
        stateService.activeIdSubject.send(nil)

        try await waitForAsync { self.subject.clearClipboardValue == .never && !self.subject.allowUniversalClipboard }
        XCTAssertTrue(errorReporter.errors.isEmpty)
    }

    @MainActor
    func test_error_other_preservesCurrentSettings() async throws {
        try await waitForInitialization()
        stateService.clearClipboardResult = .failure(BitwardenTestError.example)
        stateService.activeIdSubject.send(nil)

        try await waitForAsync { !self.errorReporter.errors.isEmpty }
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
        XCTAssertEqual(subject.clearClipboardValue, .oneMinute)
        XCTAssertFalse(subject.allowUniversalClipboard)
    }

    @MainActor
    func test_error_allowUniversalClipboardRead_preservesPreviousSharingValue() async throws {
        try await waitForInitialization()
        subject.updateAllowUniversalClipboard(true)
        try await waitForAsync { self.stateService.allowUniversalClipboard["1"] == true }
        stateService.clearClipboardValues["1"] = .fiveMinutes
        stateService.getAllowUniversalClipboardError = BitwardenTestError.example
        stateService.activeIdSubject.send("1")

        try await waitForAsync { !self.errorReporter.errors.isEmpty }
        XCTAssertEqual(subject.clearClipboardValue, .fiveMinutes)
        XCTAssertTrue(subject.allowUniversalClipboard)
    }

    @MainActor
    func test_updateClearClipboardValue_persistsAndLogsErrors() async throws {
        try await waitForInitialization()
        subject.updateClearClipboardValue(.fiveMinutes)
        XCTAssertEqual(subject.clearClipboardValue, .fiveMinutes)
        try await waitForAsync { self.stateService.clearClipboardValues["1"] == .fiveMinutes }

        stateService.clearClipboardResult = .failure(BitwardenTestError.example)
        subject.updateClearClipboardValue(.twentySeconds)
        try await waitForAsync { !self.errorReporter.errors.isEmpty }
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    @MainActor
    func test_updateAllowUniversalClipboard_persistsAndLogsErrors() async throws {
        try await waitForInitialization()
        subject.updateAllowUniversalClipboard(true)
        XCTAssertTrue(subject.allowUniversalClipboard)
        try await waitForAsync { self.stateService.allowUniversalClipboard["1"] == true }

        stateService.setAllowUniversalClipboardError = BitwardenTestError.example
        subject.updateAllowUniversalClipboard(false)
        XCTAssertFalse(subject.allowUniversalClipboard)
        try await waitForAsync { !self.errorReporter.errors.isEmpty }
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    // MARK: Private

    func waitForInitialization() async throws {
        try await waitForAsync { [weak self] in
            guard let self else { return false }
            return subject.clearClipboardValue == .oneMinute
        }
    }
}
