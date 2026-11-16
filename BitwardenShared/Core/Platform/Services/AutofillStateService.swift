import Foundation

// MARK: - AutofillStateService

/// A service that provides state management functionality around autofill.
///
protocol AutofillStateService { // sourcery: AutoMockable
    /// Gets whether the user has opted out of the vault's autofill action card. This applies to
    /// all accounts on the device.
    ///
    /// - Returns: `true` if the user opted out of the autofill action card.
    ///
    func getAutofillActionCardOptedOut() async -> Bool

    /// Gets the time of the last request to turn on credential provider.
    ///
    /// - Returns: The last time a request to turn on credential provider was done.
    ///
    func getLastRequestToTurnOnCredentialProvider() async -> Date?

    /// Sets whether the user has opted out of the vault's autofill action card. This applies to
    /// all accounts on the device.
    ///
    /// - Parameter optedOut: Whether the user opted out of the autofill action card.
    ///
    func setAutofillActionCardOptedOut(_ optedOut: Bool) async

    /// Sets the time of the last request to turn on credential provider.
    ///
    /// - Parameter date: The time of the last request to turn on credential provider.
    ///
    func setLastRequestToTurnOnCredentialProvider(_ date: Date?) async
}
