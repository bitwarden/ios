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

    /// The service used for managing items
    let authenticatorItemRepository: AuthenticatorItemRepository

    /// The service used by the application to manage camera use.
    let cameraService: CameraService

    /// The service used by the application to handle encryption and decryption tasks.
    let clientService: ClientService

    /// The service used by the application to encrypt and decrypt items
    let cryptographyService: CryptographyService

    /// The service used by the application to report non-fatal errors.
    let errorReporter: ErrorReporter

    /// The service used by the application for sharing data with other apps.
    let pasteboardService: PasteboardService

    /// Provides the present time for TOTP Code Calculation.
    let timeProvider: TimeProvider

    /// The service used by the application to validate TOTP keys and produce TOTP values.
    let totpService: TOTPService

    // MARK: Initialization

    /// Initialize a `ServiceContainer`.
    ///
    /// - Parameters:
    ///   - application: The application instance.
    ///   - authenticatorItemRepository: The service to manage items
    ///   - cameraService: The service used by the application to manage camera use.
    ///   - clientService: The service used by the application to handle encryption and decryption tasks.
    ///   - cryptographyService: The service used by the application to encrypt and decrypt items
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - pasteboardService: The service used by the application for sharing data with other apps.
    ///   - timeProvider: Provides the present time for TOTP Code Calculation.
    ///   - totpService: The service used by the application to validate TOTP keys and produce TOTP values.
    ///
    init(
        application: Application?,
        authenticatorItemRepository: AuthenticatorItemRepository,
        cameraService: CameraService,
        cryptographyService: CryptographyService,
        clientService: ClientService,
        errorReporter: ErrorReporter,
        pasteboardService: PasteboardService,
        timeProvider: TimeProvider,
        totpService: TOTPService
    ) {
        self.application = application
        self.authenticatorItemRepository = authenticatorItemRepository
        self.cameraService = cameraService
        self.clientService = clientService
        self.cryptographyService = cryptographyService
        self.errorReporter = errorReporter
        self.pasteboardService = pasteboardService
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
        let cameraService = DefaultCameraService()
        let clientService = DefaultClientService()
        let cryptographyService = DefaultCryptographyService()
        let dataStore = DataStore(errorReporter: errorReporter)
        let timeProvider = CurrentTime()

        let totpService = DefaultTOTPService(
            clientVault: clientService.clientVault(),
            errorReporter: errorReporter,
            timeProvider: timeProvider
        )

        let pasteboardService = DefaultPasteboardService(
            errorReporter: errorReporter
        )
        let authenticatorItemService = DefaultAuthenticatorItemService(
            authenticatorItemDataStore: dataStore
        )
        let authenticatorItemRepository = DefaultAuthenticatorItemRepository(
            authenticatorItemService: authenticatorItemService,
            cryptographyService: cryptographyService
        )

        self.init(
            application: application,
            authenticatorItemRepository: authenticatorItemRepository,
            cameraService: cameraService,
            cryptographyService: cryptographyService,
            clientService: clientService,
            errorReporter: errorReporter,
            pasteboardService: pasteboardService,
            timeProvider: timeProvider,
            totpService: totpService
        )
    }
}
