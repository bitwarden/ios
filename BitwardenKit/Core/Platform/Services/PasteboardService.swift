import UIKit
import UniformTypeIdentifiers

// MARK: - PasteboardService

/// A protocol for a service used by the application for sharing data with other apps.
///
public protocol PasteboardService: AnyObject { // sourcery: AutoMockable
    /// Indicates whether Universal Clipboard is allowed when copying.
    var allowUniversalClipboard: Bool { get }

    /// The time after which the clipboard should clear.
    var clearClipboardValue: ClearClipboardValue { get }

    /// Copies a string value to the system pasteboard and sets a timer to clear the clipboard, if applicable.
    ///
    /// - Parameter string: The string value to copy.
    ///
    func copy(_ string: String)

    /// Updates the setting to allow or disallow Universal Clipboard.
    ///
    /// - Parameter allowUniversalClipboard: A Boolean value indicating whether Universal Clipboard should be allowed.
    ///
    func updateAllowUniversalClipboard(_ allowUniversalClipboard: Bool)

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
public class DefaultPasteboardService: PasteboardService {
    // MARK: Properties

    /// The object used to publish changes to the active account.
    private let activeAccountIdPublisherProvider: ActiveAccountIdPublisherProvider

    /// Indicates whether Universal Clipboard is allowed when copying.
    public private(set) var allowUniversalClipboard: Bool = false

    /// The time after which the clipboard should clear.
    public private(set) var clearClipboardValue: ClearClipboardValue = .never

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// The pasteboard used by this service.
    private let pasteboard: PasteboardProtocol

    /// The service used by the application to manage the pasteboard state.
    private let stateService: PasteboardStateService

    /// Provides the present time for calculating when copied content expires.
    private let timeProvider: TimeProvider

    // MARK: Initialization

    /// Initializes a new `DefaultPasteboardService`.
    ///
    /// - Parameters:
    ///   - activeAccountIdPublisherProvider: The object used to publish changes to the active account.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - pasteboard: The pasteboard used by the service. Default is `.general`.
    ///   - stateService: The service used by the application to manage the pasteboard state.
    ///   - timeProvider: Provides the present time for calculating when copied content expires.
    ///
    public init(
        activeAccountIdPublisherProvider: ActiveAccountIdPublisherProvider,
        errorReporter: ErrorReporter,
        pasteboard: PasteboardProtocol = UIPasteboard.general,
        stateService: PasteboardStateService,
        timeProvider: TimeProvider = CurrentTime(),
    ) {
        self.activeAccountIdPublisherProvider = activeAccountIdPublisherProvider
        self.errorReporter = errorReporter
        self.pasteboard = pasteboard
        self.stateService = stateService
        self.timeProvider = timeProvider

        // Get the value of the clipboard settings for the currently active user.
        Task {
            for await userId in await self.activeAccountIdPublisherProvider.activeAccountIdPublisher().values {
                guard let userId else {
                    // Revert to the default values if the user isn't logged in.
                    clearClipboardValue = .never
                    allowUniversalClipboard = false
                    continue
                }
                do {
                    clearClipboardValue = try await self.stateService.getClearClipboardValue(userId: userId)
                    allowUniversalClipboard = try await self.stateService.getAllowUniversalClipboard(userId: userId)
                } catch {
                    self.errorReporter.log(error: error)
                }
            }
        }
    }

    // MARK: Methods

    public func copy(_ string: String) {
        var options: [UIPasteboard.OptionsKey: Any] = [.localOnly: !allowUniversalClipboard]
        if clearClipboardValue != .never {
            // Set the expiration date if the clear clipboard preference is not never.
            options[.expirationDate] = timeProvider.presentTime.addingTimeInterval(Double(clearClipboardValue.rawValue))
        }
        pasteboard.setItems([[UTType.utf8PlainText.identifier: string]], options: options)
    }

    public func updateAllowUniversalClipboard(_ allowUniversalClipboard: Bool) {
        self.allowUniversalClipboard = allowUniversalClipboard

        // Update the value in storage.
        Task {
            do {
                try await self.stateService.setAllowUniversalClipboard(allowUniversalClipboard, userId: nil)
            } catch {
                self.errorReporter.log(error: error)
            }
        }
    }

    public func updateClearClipboardValue(_ clearClipboardValue: ClearClipboardValue) {
        self.clearClipboardValue = clearClipboardValue

        // Update the value in storage.
        Task {
            do {
                try await self.stateService.setClearClipboardValue(clearClipboardValue, userId: nil)
            } catch {
                self.errorReporter.log(error: error)
            }
        }
    }
}
