import BitwardenSdk

/// The services provided by the `ServiceContainer`.
typealias Services = HasTimeProvider

/// Protocol for an object that provides a `TimeProvider`.
///
protocol HasTimeProvider {
    /// Provides the present time for TOTP Code Calculation.
    var timeProvider: TimeProvider { get }
}
