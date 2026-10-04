import BitwardenKit
import UIKit
import UniformTypeIdentifiers

// MARK: - Pasteboard

/// The pasteboard operations used to copy content with sharing and expiration options.
///
protocol Pasteboard {
    /// Writes items to the pasteboard with the specified options.
    ///
    /// - Parameters:
    ///   - items: The items to copy.
    ///   - options: The sharing and expiration policy for the items.
    ///
    func setItems(_ items: [[String: Any]], options: [UIPasteboard.OptionsKey: Any])
}

extension UIPasteboard: Pasteboard {}

// MARK: - PasteboardService

/// A protocol for a service used by the application for sharing data with other apps.
///
protocol PasteboardService: AnyObject {
    /// The time after which the clipboard should clear.
    var clearClipboardValue: ClearClipboardValue { get }

    /// Copies a string value to the system pasteboard and sets a timer to clear the clipboard, if applicable.
    ///
    /// - Parameter string: The string value to copy.
    ///
    func copy(_ string: String)

    /// Update the timeout period after which the clipboard should be cleared.
    ///
    /// - Parameter clearClipboardValue: The time after which the clipboard should be cleared.
    ///
    func updateClearClipboardValue(_ clearClipboardValue: ClearClipboardValue)
}

// MARK: - DefaultPasteboardService

/// A default implementation of a `PasteboardService` that uses the system pasteboard for sharing
/// data with other apps.
///
class DefaultPasteboardService: PasteboardService {
    // MARK: Properties

    /// The store containing the user's clipboard sharing preference.
    private let appSettingsStore: AppSettingsStore

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// The time after which the clipboard should clear.
    var clearClipboardValue: ClearClipboardValue = .never

    /// The pasteboard used by this service.
    private let pasteboard: Pasteboard

    // MARK: Initialization

    /// Initializes a new `DefaultPasteboardService`.
    ///
    /// - Parameters:
    ///   - appSettingsStore: The store containing the user's clipboard sharing preference.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - pasteboard: The pasteboard used by the service. Default is `.general`.
    ///
    init(
        appSettingsStore: AppSettingsStore,
        errorReporter: ErrorReporter,
        pasteboard: Pasteboard = UIPasteboard.general,
    ) {
        self.appSettingsStore = appSettingsStore
        self.errorReporter = errorReporter
        self.pasteboard = pasteboard
        clearClipboardValue = .never // Once we have a state service we can make this configurable
    }

    // MARK: Methods

    func copy(_ string: String) {
        if clearClipboardValue == .never {
            pasteboard.setItems(
                [[UTType.utf8PlainText.identifier: string]],
                options: [.localOnly: !appSettingsStore.allowUniversalClipboard],
            )
        } else {
            // Set the expiration date if the clear clipboard preference is not never.
            let expirationDate = Date().addingTimeInterval(Double(clearClipboardValue.rawValue))
            pasteboard.setItems(
                [[UTType.utf8PlainText.identifier: string]],
                options: [
                    .localOnly: !appSettingsStore.allowUniversalClipboard,
                    .expirationDate: expirationDate,
                ],
            )
        }
    }

    func updateClearClipboardValue(_ clearClipboardValue: ClearClipboardValue) {
        self.clearClipboardValue = clearClipboardValue
    }
}
