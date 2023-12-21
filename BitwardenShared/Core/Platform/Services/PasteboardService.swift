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

    /// The service used by the application to manage account state.
    private let stateService: StateService

    // MARK: Initialization

    /// Initializes a new `DefaultPasteboardService`.
    ///
    /// - Parameters:
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - stateService: The service used by the application to manage account state.
    ///
    init(errorReporter: ErrorReporter, stateService: StateService) {
        self.errorReporter = errorReporter
        self.stateService = stateService

        // Get the value of the clipboard setting for the currently active user.
        Task {
            for await _ in await self.stateService.activeAccountIdPublisher() {
                do {
                    clearClipboardValue = try await self.stateService.getClearClipboardValue()
                } catch {
                    self.errorReporter.log(error: error)
                }
            }
        }
    }

    // MARK: Methods

    func copy(_ string: String) {
        if clearClipboardValue == .never {
            UIPasteboard.general.setItems(
                [[UTType.utf8PlainText.identifier: string]],
                options: [.localOnly: true]
            )
        } else {
            // Set the expiration date if the clear clipboard preference is not never.
            let expirationDate = Date().addingTimeInterval(Double(clearClipboardValue.rawValue))
            UIPasteboard.general.setItems(
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

        // Update the value in storage.
        Task {
            do {
                try await self.stateService.setClearClipboardValue(clearClipboardValue)
            } catch {
                self.errorReporter.log(error: error)
            }
        }
    }
}
