// MARK: - FlightRecorderModule

/// An object that builds coordinators for the flight recorder flow.
///
@MainActor
public protocol FlightRecorderModule {
    /// Initializes a coordinator for navigating between `FlightRecorderRoute`s.
    ///
    /// - Parameters:
    ///   - stackNavigator: The stack navigator that will be used to navigate between routes.
    /// - Returns: A coordinator that can navigate to `FlightRecorderRoute`s.
    ///
    func makeFlightRecorderCoordinator(
        stackNavigator: StackNavigator,
    ) -> AnyCoordinator<FlightRecorderRoute, Void>
}
