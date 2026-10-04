import BitwardenKit
import BitwardenKitMocks
import Testing
import UIKit
import UniformTypeIdentifiers

@testable import AuthenticatorShared

// MARK: - PasteboardServiceTests

@MainActor
struct PasteboardServiceTests {
    // MARK: Properties

    let appSettingsStore: MockAppSettingsStore
    let pasteboard: MockPasteboard
    let subject: DefaultPasteboardService

    // MARK: Setup

    init() {
        appSettingsStore = MockAppSettingsStore()
        pasteboard = MockPasteboard()
        subject = DefaultPasteboardService(
            appSettingsStore: appSettingsStore,
            errorReporter: MockErrorReporter(),
            pasteboard: pasteboard,
        )
    }

    // MARK: Tests

    /// Copies remain local by default without adding an expiration date.
    @Test
    func copy_defaultsToLocalOnly() {
        subject.copy("123456")

        #expect(pasteboard.items.first?[UTType.utf8PlainText.identifier] as? String == "123456")
        #expect(pasteboard.options[.localOnly] as? Bool == true)
        #expect(pasteboard.options[.expirationDate] == nil)
    }

    /// Each copy uses the latest preference, including enabling and then disabling it.
    @Test
    func copy_readsCurrentPreference() {
        appSettingsStore.allowUniversalClipboard = true
        subject.copy("123456")
        #expect(pasteboard.options[.localOnly] as? Bool == false)

        appSettingsStore.allowUniversalClipboard = false
        subject.copy("654321")
        #expect(pasteboard.options[.localOnly] as? Bool == true)
        #expect(pasteboard.items.first?[UTType.utf8PlainText.identifier] as? String == "654321")
    }

    /// A stored opt-in applies to the first copy after recreating the service.
    @Test
    func copy_restoresPreferenceBeforeFirstCopy() {
        appSettingsStore.allowUniversalClipboard = true
        let restartedService = DefaultPasteboardService(
            appSettingsStore: appSettingsStore,
            errorReporter: MockErrorReporter(),
            pasteboard: pasteboard,
        )

        restartedService.copy("123456")

        #expect(pasteboard.options[.localOnly] as? Bool == false)
    }

    /// Finite clipboard expiration is retained with either sharing preference.
    @Test(arguments: [false, true])
    func copy_preservesExpiration(allowUniversalClipboard: Bool) throws {
        appSettingsStore.allowUniversalClipboard = allowUniversalClipboard
        subject.updateClearClipboardValue(.tenSeconds)
        let earliestExpiration = Date().addingTimeInterval(10)

        subject.copy("123456")

        let latestExpiration = Date().addingTimeInterval(10)
        let expiration = try #require(pasteboard.options[.expirationDate] as? Date)
        #expect(expiration >= earliestExpiration)
        #expect(expiration <= latestExpiration)
        #expect(pasteboard.options[.localOnly] as? Bool == !allowUniversalClipboard)
        #expect(pasteboard.items.first?[UTType.utf8PlainText.identifier] as? String == "123456")
    }
}
