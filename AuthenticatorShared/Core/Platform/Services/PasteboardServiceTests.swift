import BitwardenKit
import BitwardenKitMocks
import Testing
import UIKit
import UniformTypeIdentifiers

@testable import AuthenticatorShared

@MainActor
struct PasteboardServiceTests {
    let appSettingsStore = MockAppSettingsStore()
    let pasteboard = MockPasteboard()
    let provider: DefaultPasteboardSettingsProvider
    let subject: DefaultPasteboardService

    init() {
        provider = DefaultPasteboardSettingsProvider(appSettingsStore: appSettingsStore)
        subject = DefaultPasteboardService(pasteboard: pasteboard, settingsProvider: provider)
    }

    @Test
    func copy_defaultsToLocalOnly() throws {
        subject.copy("123456")

        let arguments = try #require(pasteboard.setItemsReceivedArguments)
        #expect(arguments.items.first?[UTType.utf8PlainText.identifier] as? String == "123456")
        #expect(arguments.options[.localOnly] as? Bool == true)
        #expect(arguments.options[.expirationDate] == nil)
        #expect(provider.clearClipboardValue == .never)
    }

    @Test
    func copy_readsCurrentPreference() throws {
        appSettingsStore.allowUniversalClipboard = true
        subject.copy("123456")
        #expect(pasteboard.setItemsReceivedArguments?.options[.localOnly] as? Bool == false)

        appSettingsStore.allowUniversalClipboard = false
        subject.copy("654321")
        #expect(pasteboard.setItemsReceivedArguments?.options[.localOnly] as? Bool == true)
        let copiedText = pasteboard.setItemsReceivedArguments?.items.first?[UTType.utf8PlainText.identifier] as? String
        #expect(copiedText == "654321")
    }

    @Test
    func copy_restoresPreferenceBeforeFirstCopy() {
        appSettingsStore.allowUniversalClipboard = true
        let restartedService = DefaultPasteboardService(
            pasteboard: pasteboard,
            settingsProvider: DefaultPasteboardSettingsProvider(appSettingsStore: appSettingsStore),
        )

        restartedService.copy("123456")

        #expect(pasteboard.setItemsReceivedArguments?.options[.localOnly] as? Bool == false)
    }

    @Test(arguments: [false, true])
    func copy_preservesExpiration(allowUniversalClipboard: Bool) throws {
        provider.updateAllowUniversalClipboard(allowUniversalClipboard)
        provider.updateClearClipboardValue(.tenSeconds)
        let earliestExpiration = Date().addingTimeInterval(10)

        subject.copy("123456")

        let latestExpiration = Date().addingTimeInterval(10)
        let arguments = try #require(pasteboard.setItemsReceivedArguments)
        let expiration = try #require(arguments.options[.expirationDate] as? Date)
        #expect(expiration >= earliestExpiration)
        #expect(expiration <= latestExpiration)
        #expect(arguments.options[.localOnly] as? Bool == !allowUniversalClipboard)
    }

    @Test
    func provider_updatesStoreAndMemory() {
        provider.updateAllowUniversalClipboard(true)
        provider.updateClearClipboardValue(.twentySeconds)

        #expect(appSettingsStore.allowUniversalClipboard)
        #expect(provider.allowUniversalClipboard)
        #expect(provider.clearClipboardValue == .twentySeconds)
    }
}
