import BitwardenKit
import Foundation

/// The services provided by the `ServiceContainer`.
typealias Services = HasErrorReportBuilder & HasPasskeyRegistryService

/// The default implementation of a container that provides the services used by the application.
///
public class ServiceContainer: Services {
    // MARK: Properties

    /// A helper for building an error report containing the details of an error that occurred.
    public let errorReportBuilder: ErrorReportBuilder

    /// The service that tracks passkeys registered through the Test Harness.
    let passkeyRegistryService: PasskeyRegistryService

    // MARK: Initialization

    /// Initialize a `ServiceContainer`.
    ///
    /// - Parameters:
    ///   - errorReportBuilder: A helper for building an error report containing the details of an
    ///     error that occurred.
    public init(
        errorReportBuilder: ErrorReportBuilder,
    ) {
        self.errorReportBuilder = errorReportBuilder
        passkeyRegistryService = DefaultPasskeyRegistryService()
    }

    public convenience init() {
        let appInfoService = DefaultAppInfoService(configServiceProvider: { nil })
        let stateService = DefaultStateService()
        let timeProvider = CurrentTime()

        let errorReportBuilder = DefaultErrorReportBuilder(
            activeAccountStateProvider: stateService,
            appInfoService: appInfoService,
            timeProvider: timeProvider,
        )

        self.init(
            errorReportBuilder: errorReportBuilder,
        )
    }
}
