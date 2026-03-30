import Foundation

// MARK: - AutofillStateService

/// A service that provides state management functionality around autofill.
///
protocol AutofillStateService { // sourcery: AutoMockable
    /// Gets the time of the last request to turn on credential provider.
    ///
    /// - Returns: The last time a request to turn on credential provider was done.
    ///
    func getLastRequestToTurnOnCredentialProvider() async -> Date?

    /// Sets the time of the last request to turn on credential provider.
    ///
    /// - Parameter date: The time of the last request to turn on credential provider.
    ///
    func setLastRequestToTurnOnCredentialProvider(_ date: Date?) async
}
