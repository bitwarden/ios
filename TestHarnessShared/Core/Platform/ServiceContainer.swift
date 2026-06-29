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
        if #available(iOS 17.4, *) {
            passkeyRegistryService = DefaultPasskeyRegistryService()
        } else {
            passkeyRegistryService = UnavailablePasskeyRegistryService()
        }
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

// MARK: - UnavailablePasskeyRegistryService

/// No-op registry used when the device OS is below the iOS 17.4 minimum required by
/// `ASCredentialIdentityStore`. Passkey features are also unavailable below iOS 17, so this
/// implementation is never meaningfully exercised at runtime.
private struct UnavailablePasskeyRegistryService: PasskeyRegistryService {
    func savePasskey(_: PasskeyEntry) async {}
    func loadPasskeys() async -> [PasskeyEntry] { [] }
    func deletePasskey(_: PasskeyEntry) async {}
    func clearAll() async {}
}
