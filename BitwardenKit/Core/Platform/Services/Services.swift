// swiftlint:disable:this file_name

/// Protocol for an object that provides a `ConfigService`.
///
public protocol HasConfigService {
    /// The service to get server-specified configuration.
    var configService: ConfigService { get }
}

/// Protocol for an object that provides an `ErrorReportBuilder`.
///
public protocol HasErrorReportBuilder {
    /// A helper for building an error report containing the details of an error that occurred.
    var errorReportBuilder: ErrorReportBuilder { get }
}

/// Protocol for an object that provides an `EnvironmentService`.
///
public protocol HasEnvironmentService {
    /// The service used by the application to manage the environment settings.
    var environmentService: EnvironmentService { get }
}

/// Protocol for an object that provides an `ErrorReporter`.
///
public protocol HasErrorReporter {
    /// The service used by the application to report non-fatal errors.
    var errorReporter: ErrorReporter { get }
}

/// Protocol for an object that provides a `FlightRecorder`.
///
public protocol HasFlightRecorder {
    /// The service used by the application for recording temporary debug logs.
    var flightRecorder: FlightRecorder { get }
}

/// Protocol for an object that provides a `LanguageStateService`.
///
public protocol HasLanguageStateService {
    /// The service used by the application to manage language state.
    var languageStateService: LanguageStateService { get }
}

/// Protocol for an object that provides a `TimeProvider`.
///
public protocol HasTimeProvider {
    /// Provides the present time for TOTP Code Calculation.
    var timeProvider: TimeProvider { get }
}
