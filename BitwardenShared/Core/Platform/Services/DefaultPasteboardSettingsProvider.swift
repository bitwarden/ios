import BitwardenKit

/// Password Manager clipboard preferences backed by account-scoped state.
///
class DefaultPasteboardSettingsProvider: PasteboardSettingsProvider {
    // MARK: Properties

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// The time after which the clipboard should clear.
    var clearClipboardValue: ClearClipboardValue = .never

    /// Indicates whether Universal Clipboard is allowed when copying.
    var allowUniversalClipboard: Bool = false

    /// The service used by the application to manage account state.
    private let stateService: StateService

    // MARK: Initialization

    /// Initializes a new `DefaultPasteboardSettingsProvider`.
    ///
    /// - Parameters:
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - stateService: The service used by the application to manage account state.
    ///
    init(
        errorReporter: ErrorReporter,
        stateService: StateService,
    ) {
        self.errorReporter = errorReporter
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
