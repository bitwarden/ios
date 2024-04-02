import BitwardenSdk
import UIKit

/// The `ServiceContainer` contains the list of services used by the app. This can be injected into
/// `Coordinator`s throughout the app which build processors. A `Processor` can define which
/// services it needs access to by defining a typealias containing a list of services.
///
/// For example:
///
///     class ExampleProcessor: StateProcessor<ExampleState, ExampleAction, Void> {
///         typealias Services = HasExampleService
///             & HasExampleRepository
///     }
///
public class ServiceContainer: Services {
    // MARK: Properties

    /// The application instance (i.e. `UIApplication`), if the app isn't running in an extension.
    let application: Application?

    /// The service used by the application to handle encryption and decryption tasks.
    let clientService: ClientService

    /// The service used by the application to report non-fatal errors.
    let errorReporter: ErrorReporter

    /// The repository used by the application to manage item data for the UI layer.
    let itemRepository: ItemRepository

    /// Provides the present time for TOTP Code Calculation.
    let timeProvider: TimeProvider

    /// The service used by the application to validate TOTP keys and produce TOTP values.
    let totpService: TOTPService

    // MARK: Initialization

    /// Initialize a `ServiceContainer`.
    ///
    /// - Parameters:
    ///   - application: The application instance.
    ///   - clientService: The service used by the application to handle encryption and decryption tasks.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - itemRepository: The repository used by the application to manage vault data for the UI layer.
    ///   - timeProvider: Provides the present time for TOTP Code Calculation.
    ///   - totpService: The service used by the application to validate TOTP keys and produce TOTP values.
    ///
    init(
        application: Application?,
        clientService: ClientService,
        errorReporter: ErrorReporter,
        itemRepository: ItemRepository,
        timeProvider: TimeProvider,
        totpService: TOTPService
    ) {
        self.application = application
        self.clientService = clientService
        self.errorReporter = errorReporter
        self.itemRepository = itemRepository
        self.timeProvider = timeProvider
        self.totpService = totpService
    }

    /// A convenience initializer to initialize the `ServiceContainer` with the default services.
    ///
    /// - Parameters:
    ///   - application: The application instance.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///
    public convenience init(
        application: Application? = nil,
        errorReporter: ErrorReporter
    ) {
        let clientService = DefaultClientService()

        let timeProvider = CurrentTime()

        let totpService = DefaultTOTPService()

        let itemRepository = DefaultItemRepository(
            clientVault: clientService.clientVault(),
            errorReporter: errorReporter,
            timeProvider: timeProvider)

        self.init(
            application: application,
            clientService: clientService,
            errorReporter: errorReporter,
            itemRepository: itemRepository,
            timeProvider: timeProvider,
            totpService: totpService
        )
    }
}
