// MARK: - FlightRecorderStateService

/// A protocol for a service that provides state management functionality required by the flight recorder.
///
public protocol FlightRecorderStateService {
    /// Returns the identifier for the currently active account.
    ///
    /// - Returns: The active account's unique identifier.
    /// - Throws: An error if the active account cannot be determined.
    ///
    func getActiveAccountId() async throws -> String

    /// Retrieves the persisted flight recorder data.
    ///
    /// - Returns: The stored `FlightRecorderData` if available, otherwise `nil`.
    ///
    func getFlightRecorderData() async -> FlightRecorderData?

    /// Persists the flight recorder data to storage.
    ///
    /// - Parameter data: The `FlightRecorderData` to persist, or `nil` to clear the stored data.
    ///
    func setFlightRecorderData(_ data: FlightRecorderData?) async
}
