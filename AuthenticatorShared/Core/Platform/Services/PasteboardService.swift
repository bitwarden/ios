import UIKit
import UniformTypeIdentifiers

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

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// The time after which the clipboard should clear.
    var clearClipboardValue: ClearClipboardValue = .never

    /// The pasteboard used by this service.
    private let pasteboard: UIPasteboard

    // MARK: Initialization

    /// Initializes a new `DefaultPasteboardService`.
    ///
    /// - Parameters:
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - pasteboard: The pasteboard used by the service. Default is `.general`.
    ///
    init(
        errorReporter: ErrorReporter,
        pasteboard: UIPasteboard = .general
    ) {
        self.errorReporter = errorReporter
        self.pasteboard = pasteboard
        clearClipboardValue = .never // Once we have a state service we can make this configurable
    }

    // MARK: Methods

    func copy(_ string: String) {
        if clearClipboardValue == .never {
            pasteboard.setItems(
                [[UTType.utf8PlainText.identifier: string]],
                options: [.localOnly: true]
            )
        } else {
            // Set the expiration date if the clear clipboard preference is not never.
            let expirationDate = Date().addingTimeInterval(Double(clearClipboardValue.rawValue))
            pasteboard.setItems(
                [[UTType.utf8PlainText.identifier: string]],
                options: [
                    .localOnly: true,
                    .expirationDate: expirationDate,
                ]
            )
        }
    }

    func updateClearClipboardValue(_ clearClipboardValue: ClearClipboardValue) {
        self.clearClipboardValue = clearClipboardValue
    }
}
