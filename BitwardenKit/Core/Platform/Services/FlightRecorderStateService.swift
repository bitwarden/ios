// MARK: - FlightRecorderStateService

/// A protocol for a service that provides state management functionality required by the flight recorder.
///
public protocol FlightRecorderStateService: ActiveAccountStateProvider {
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
