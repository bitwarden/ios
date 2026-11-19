import Combine
import Foundation

// MARK: - AutofillStateService

/// A service that provides state management functionality around autofill.
///
protocol AutofillStateService { // sourcery: AutoMockable
    /// A publisher for the time the user last dismissed the vault's autofill action card. This is
    /// persisted and applies to all accounts on the device.
    ///
    /// - Returns: A publisher that emits the time the autofill action card was dismissed, or `nil`
    ///   if it hasn't been, starting with the current value.
    ///
    func autofillActionCardDismissedDatePublisher() async -> AnyPublisher<Date?, Never>

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

    /// Sets the time the user last dismissed the vault's autofill action card. This is persisted
    /// and applies to all accounts on the device.
    ///
    /// - Parameter date: The time the autofill action card was dismissed, or `nil` to clear it.
    ///
    func setAutofillActionCardDismissedDate(_ date: Date?) async

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
