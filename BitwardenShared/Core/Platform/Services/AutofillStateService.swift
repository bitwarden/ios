import Combine
import Foundation

// MARK: - AutofillStateService

/// A service that provides state management functionality around autofill.
///
protocol AutofillStateService { // sourcery: AutoMockable
    /// A publisher for whether the vault's autofill action card was dismissed during this app
    /// session. This isn't persisted, so it resets on the next cold launch.
    ///
    /// - Returns: A publisher that emits `true` while the autofill action card is dismissed for the
    ///   session, starting with the current value.
    ///
    func autofillActionCardDismissedForSessionPublisher() async -> AnyPublisher<Bool, Never>

    /// A publisher for whether the user has opted out of the vault's autofill action card. This
    /// applies to all accounts on the device.
    ///
    /// - Returns: A publisher that emits `true` while the user is opted out of the autofill action
    ///   card, starting with the current value.
    ///
    func autofillActionCardOptedOutPublisher() async -> AnyPublisher<Bool, Never>

    /// Gets the time of the last request to turn on credential provider.
    ///
    /// - Returns: The last time a request to turn on credential provider was done.
    ///
    func getLastRequestToTurnOnCredentialProvider() async -> Date?

    /// Sets whether the vault's autofill action card is dismissed for the current app session.
    /// This isn't persisted.
    ///
    /// - Parameter dismissed: Whether the autofill action card is dismissed for the session.
    ///
    func setAutofillActionCardDismissedForSession(_ dismissed: Bool) async

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
