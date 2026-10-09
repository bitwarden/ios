import Foundation
import Testing
import UIKit
import UniformTypeIdentifiers

@testable import BitwardenKit
@testable import BitwardenKitMocks

@MainActor
struct PasteboardServiceTests {
    let pasteboard = MockPasteboard()
    let settingsProvider = MockPasteboardSettingsProvider()
    let timeProvider = MockTimeProvider(.mockTime(Date(timeIntervalSince1970: 1000)))
    let subject: DefaultPasteboardService

    init() {
        settingsProvider.allowUniversalClipboard = false
        settingsProvider.clearClipboardValue = .never
        subject = DefaultPasteboardService(
            pasteboard: pasteboard,
            settingsProvider: settingsProvider,
            timeProvider: timeProvider,
        )
    }

    @Test(arguments: [false, true])
    func copy_appliesSharingPreference(allowUniversalClipboard: Bool) throws {
        settingsProvider.allowUniversalClipboard = allowUniversalClipboard

        subject.copy("123456")

        let arguments = try #require(pasteboard.setItemsReceivedArguments)
        #expect(pasteboard.setItemsCallsCount == 1)
        #expect(arguments.items.first?[UTType.utf8PlainText.identifier] as? String == "123456")
        #expect(arguments.options[.localOnly] as? Bool == !allowUniversalClipboard)
        #expect(arguments.options[.expirationDate] == nil)
    }

    @Test(arguments: [ClearClipboardValue.tenSeconds, .fiveMinutes], [false, true])
    func copy_appliesExactExpiration(clearClipboardValue: ClearClipboardValue, allowUniversalClipboard: Bool) throws {
        settingsProvider.allowUniversalClipboard = allowUniversalClipboard
        settingsProvider.clearClipboardValue = clearClipboardValue

        subject.copy("text")

        let options = try #require(pasteboard.setItemsReceivedArguments?.options)
        let expectedExpiration = timeProvider.presentTime.addingTimeInterval(Double(clearClipboardValue.rawValue))
        #expect(options[.expirationDate] as? Date == expectedExpiration)
        #expect(options[.localOnly] as? Bool == !allowUniversalClipboard)
    }

    @Test
    func copy_readsChangedSettingsOnNextWrite() throws {
        subject.copy("first")
        settingsProvider.allowUniversalClipboard = true
        settingsProvider.clearClipboardValue = .twentySeconds

        subject.copy("second")

        let arguments = try #require(pasteboard.setItemsReceivedArguments)
        #expect(pasteboard.setItemsCallsCount == 2)
        #expect(arguments.items.first?[UTType.utf8PlainText.identifier] as? String == "second")
        #expect(arguments.options[.localOnly] as? Bool == false)
        #expect(arguments.options[.expirationDate] as? Date == timeProvider.presentTime.addingTimeInterval(20))
    }

    @Test
    func preferences_delegateToProvider() {
        settingsProvider.allowUniversalClipboard = true
        settingsProvider.clearClipboardValue = .oneMinute
        #expect(subject.allowUniversalClipboard)
        #expect(subject.clearClipboardValue == .oneMinute)

        subject.updateAllowUniversalClipboard(false)
        subject.updateClearClipboardValue(.tenSeconds)

        #expect(settingsProvider.updateAllowUniversalClipboardReceivedAllowUniversalClipboard == false)
        #expect(settingsProvider.updateClearClipboardValueReceivedClearClipboardValue == .tenSeconds)
    }
}
