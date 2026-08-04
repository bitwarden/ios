import BitwardenKit
import Foundation

/// The services provided by the `ServiceContainer`.
typealias Services = HasErrorReportBuilder
    & HasSDKPasskeyService

/// The default implementation of a container that provides the services used by the application.
///
public class ServiceContainer: Services {
    // MARK: Properties

    /// A helper for building an error report containing the details of an error that occurred.
    public let errorReportBuilder: ErrorReportBuilder

    /// The service used to perform passkey registration and authentication through the
    /// Bitwarden SDK.
    public let sdkPasskeyService: SDKPasskeyService

    // MARK: Initialization

    /// Initialize a `ServiceContainer`.
    ///
    /// - Parameters:
    ///   - errorReportBuilder: A helper for building an error report containing the details of an
    ///     error that occurred.
    ///   - sdkPasskeyService: The service used to perform passkey registration and
    ///     authentication through the Bitwarden SDK.
    public init(
        errorReportBuilder: ErrorReportBuilder,
        sdkPasskeyService: SDKPasskeyService,
    ) {
        self.errorReportBuilder = errorReportBuilder
        self.sdkPasskeyService = sdkPasskeyService
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
            sdkPasskeyService: DefaultSDKPasskeyService(),
        )
    }
}
