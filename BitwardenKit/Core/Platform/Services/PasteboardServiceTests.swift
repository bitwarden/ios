import Combine
import Foundation
import TestHelpers
import Testing
import UIKit
import UniformTypeIdentifiers

@testable import BitwardenKit
@testable import BitwardenKitMocks

@MainActor
struct PasteboardServiceTests {
    // MARK: Properties

    let activeAccountIdSubject = CurrentValueSubject<String?, Never>("1")
    let errorReporter = MockErrorReporter()
    let pasteboard = MockPasteboardProtocol()
    let stateService = MockPasteboardStateService()
    let timeProvider = MockTimeProvider(.mockTime(Date(timeIntervalSince1970: 1000)))
    let subject: DefaultPasteboardService

    // MARK: Setup

    init() {
        stateService.activeAccountIdPublisherReturnValue = activeAccountIdSubject.eraseToAnyPublisher()
        stateService.getAllowUniversalClipboardReturnValue = false
        stateService.getClearClipboardValueReturnValue = .oneMinute
        subject = DefaultPasteboardService(
            errorReporter: errorReporter,
            pasteboard: pasteboard,
            stateService: stateService,
            timeProvider: timeProvider,
        )
    }

    // MARK: Tests

    /// `copy(_:)` sets whether the copied text is local only based on the Universal Clipboard setting.
    @Test(arguments: [false, true])
    func copy_allowUniversalClipboard(allowUniversalClipboard: Bool) async throws {
        try await waitForInitialization()
        subject.updateAllowUniversalClipboard(allowUniversalClipboard)
        subject.updateClearClipboardValue(.never)

        subject.copy("123456")

        let arguments = try #require(pasteboard.setItemsReceivedArguments)
        #expect(pasteboard.setItemsCallsCount == 1)
        #expect(arguments.items.first?[UTType.utf8PlainText.identifier] as? String == "123456")
        #expect(arguments.options[.localOnly] as? Bool == !allowUniversalClipboard)
        #expect(arguments.options[.expirationDate] == nil)
    }

    /// `copy(_:)` sets the expiration date based on the clear clipboard setting, regardless of the
    /// Universal Clipboard setting.
    @Test(arguments: [ClearClipboardValue.tenSeconds, .fiveMinutes], [false, true])
    func copy_clearClipboardValue(
        clearClipboardValue: ClearClipboardValue,
        allowUniversalClipboard: Bool,
    ) async throws {
        try await waitForInitialization()
        subject.updateAllowUniversalClipboard(allowUniversalClipboard)
        subject.updateClearClipboardValue(clearClipboardValue)

        subject.copy("text")

        let options = try #require(pasteboard.setItemsReceivedArguments?.options)
        let expectedExpiration = timeProvider.presentTime.addingTimeInterval(Double(clearClipboardValue.rawValue))
        #expect(options[.expirationDate] as? Date == expectedExpiration)
        #expect(options[.localOnly] as? Bool == !allowUniversalClipboard)
    }

    /// The service loads the settings for the active account when it's initialized.
    @Test
    func init_loadsSettingsForActiveAccount() async throws {
        try await waitForInitialization()

        #expect(subject.clearClipboardValue == .oneMinute)
        #expect(!subject.allowUniversalClipboard)
        #expect(stateService.getClearClipboardValueReceivedUserId == "1")
        #expect(stateService.getAllowUniversalClipboardReceivedUserId == "1")
    }

    /// The service loads the settings for the new account when the active account changes.
    @Test
    func activeAccountChanged_loadsSettingsForNewAccount() async throws {
        try await waitForInitialization()
        stateService.getAllowUniversalClipboardClosure = { $0 == "2" }
        stateService.getClearClipboardValueClosure = { $0 == "2" ? .fiveMinutes : .oneMinute }

        activeAccountIdSubject.send("2")

        try await waitForAsync {
            subject.clearClipboardValue == .fiveMinutes && subject.allowUniversalClipboard
        }
    }

    /// The service reverts to the default settings without logging an error when there isn't an
    /// active account.
    @Test
    func activeAccountChanged_noActiveAccount() async throws {
        try await waitForInitialization()
        subject.updateAllowUniversalClipboard(true)

        activeAccountIdSubject.send(nil)

        try await waitForAsync {
            subject.clearClipboardValue == .never && !subject.allowUniversalClipboard
        }
        #expect(errorReporter.errors.isEmpty)
    }

    /// The service logs an error and keeps the current settings if loading the settings fails.
    @Test
    func activeAccountChanged_error() async throws {
        try await waitForInitialization()
        stateService.getClearClipboardValueThrowableError = BitwardenTestError.example

        activeAccountIdSubject.send("2")

        try await waitForAsync { !errorReporter.errors.isEmpty }
        #expect(errorReporter.errors as? [BitwardenTestError] == [.example])
        #expect(subject.clearClipboardValue == .oneMinute)
        #expect(!subject.allowUniversalClipboard)
    }

    /// `updateAllowUniversalClipboard(_:)` updates the setting and persists it for the active account.
    @Test
    func updateAllowUniversalClipboard() async throws {
        try await waitForInitialization()

        subject.updateAllowUniversalClipboard(true)

        #expect(subject.allowUniversalClipboard)
        try await waitForAsync { stateService.setAllowUniversalClipboardCallsCount == 1 }
        #expect(stateService.setAllowUniversalClipboardReceivedArguments?.allowUniversalClipboard == true)
        #expect(stateService.setAllowUniversalClipboardReceivedArguments?.userId == nil)
    }

    /// `updateAllowUniversalClipboard(_:)` logs an error if persisting the setting fails.
    @Test
    func updateAllowUniversalClipboard_error() async throws {
        try await waitForInitialization()
        stateService.setAllowUniversalClipboardThrowableError = BitwardenTestError.example

        subject.updateAllowUniversalClipboard(true)

        #expect(subject.allowUniversalClipboard)
        try await waitForAsync { !errorReporter.errors.isEmpty }
        #expect(errorReporter.errors as? [BitwardenTestError] == [.example])
    }

    /// `updateClearClipboardValue(_:)` updates the setting and persists it for the active account.
    @Test
    func updateClearClipboardValue() async throws {
        try await waitForInitialization()

        subject.updateClearClipboardValue(.fiveMinutes)

        #expect(subject.clearClipboardValue == .fiveMinutes)
        try await waitForAsync { stateService.setClearClipboardValueCallsCount == 1 }
        #expect(stateService.setClearClipboardValueReceivedArguments?.clearClipboardValue == .fiveMinutes)
        #expect(stateService.setClearClipboardValueReceivedArguments?.userId == nil)
    }

    /// `updateClearClipboardValue(_:)` logs an error if persisting the setting fails.
    @Test
    func updateClearClipboardValue_error() async throws {
        try await waitForInitialization()
        stateService.setClearClipboardValueThrowableError = BitwardenTestError.example

        subject.updateClearClipboardValue(.twentySeconds)

        #expect(subject.clearClipboardValue == .twentySeconds)
        try await waitForAsync { !errorReporter.errors.isEmpty }
        #expect(errorReporter.errors as? [BitwardenTestError] == [.example])
    }

    // MARK: Private

    /// Waits for the service to load the settings for the initial active account.
    private func waitForInitialization() async throws {
        try await waitForAsync { stateService.getAllowUniversalClipboardCallsCount == 1 }
    }
}
