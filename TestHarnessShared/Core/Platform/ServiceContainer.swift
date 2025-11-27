import BitwardenKit
import Foundation

/// The services provided by the `ServiceContainer`.
typealias Services = HasErrorReportBuilder

/// The default implementation of a container that provides the services used by the application.
///
public class ServiceContainer: Services {
    // MARK: Properties

    /// A helper for building an error report containing the details of an error that occurred.
    public let errorReportBuilder: ErrorReportBuilder

    // MARK: Initialization

    /// Initialize a `ServiceContainer`.
    ///
    /// - Parameters:
    ///   - errorReportBuilder: A helper for building an error report containing the details of an
    public init(
        errorReportBuilder: ErrorReportBuilder,
    ) {
        self.errorReportBuilder = errorReportBuilder
    }

    public convenience init() {
        let appInfoService = DefaultAppInfoService()
        let stateService = DefaultStateService()

        let errorReportBuilder = DefaultErrorReportBuilder(
            activeAccountStateProvider: stateService,
            appInfoService: appInfoService,
        )

        self.init(
            errorReportBuilder: errorReportBuilder,
        )
    }
}
