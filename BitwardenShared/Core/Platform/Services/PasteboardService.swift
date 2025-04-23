import BitwardenKit
import UIKit
import UniformTypeIdentifiers

/// A protocol for a service used by the application for sharing data with other apps.
///
protocol PasteboardService: AnyObject {
    /// The time after which the clipboard should clear.
    var clearClipboardValue: ClearClipboardValue { get }

    /// Indicates whether Universal Clipboard is allowed when copying.
    var allowUniversalClipboard: Bool { get }

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

    /// Updates the setting to allow or disallow Universal Clipboard.
    ///
    /// - Parameter allowUniversalClipboard: A Boolean value indicating whether Universal Clipboard should be allowed.
    ///
    func updateAllowUniversalClipboard(_ allowUniversalClipboard: Bool)
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

    /// Indicates whether Universal Clipboard is allowed when copying.
    var allowUniversalClipboard: Bool = false

    /// The pasteboard used by this service.
    private let pasteboard: UIPasteboard

    /// The service used by the application to manage account state.
    private let stateService: StateService

    // MARK: Initialization

    /// Initializes a new `DefaultPasteboardService`.
    ///
    /// - Parameters:
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - pasteboard: The pasteboard used by the service. Default is `.general`.
    ///   - stateService: The service used by the application to manage account state.
    ///
    init(
        errorReporter: ErrorReporter,
        pasteboard: UIPasteboard = .general,
        stateService: StateService
    ) {
        self.errorReporter = errorReporter
        self.pasteboard = pasteboard
        self.stateService = stateService

        // Get the value of the clipboard setting for the currently active user.
        Task {
            for await _ in await self.stateService.activeAccountIdPublisher().values {
                do {
                    clearClipboardValue = try await self.stateService.getClearClipboardValue()
                    allowUniversalClipboard = try await self.stateService.getAllowUniversalClipboard()
                } catch StateServiceError.noActiveAccount {
                    // Revert to the default value and don't record an error if the user isn't logged in.
                    clearClipboardValue = .never
                    allowUniversalClipboard = false
                } catch {
                    self.errorReporter.log(error: error)
                }
            }
        }
    }

    // MARK: Methods

    func copy(_ string: String) {
        if clearClipboardValue == .never {
            pasteboard.setItems(
                [[UTType.utf8PlainText.identifier: string]],
                options: [.localOnly: !allowUniversalClipboard]
            )
        } else {
            // Set the expiration date if the clear clipboard preference is not never.
            let expirationDate = Date().addingTimeInterval(Double(clearClipboardValue.rawValue))
            pasteboard.setItems(
                [[UTType.utf8PlainText.identifier: string]],
                options: [
                    .localOnly: !allowUniversalClipboard,
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

    func updateAllowUniversalClipboard(_ allowUniversalClipboard: Bool) {
        self.allowUniversalClipboard = allowUniversalClipboard

        // Update the value in storage.
        Task {
            do {
                try await self.stateService.setAllowUniversalClipboard(allowUniversalClipboard)
            } catch {
                self.errorReporter.log(error: error)
            }
        }
    }
}
