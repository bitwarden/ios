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

    /// The service for persisting app setting values.
    let appSettingsStore: AppSettingsStore

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

    /// The serviced used to perform app data migrations.
    let migrationService: MigrationService

    /// The service used by the application for sharing data with other apps.
    let pasteboardService: PasteboardService

    /// The service used by the application to manage account state.
    let stateService: StateService

    /// Provides the present time for TOTP Code Calculation.
    let timeProvider: TimeProvider

    /// The service used by the application to validate TOTP keys and produce TOTP values.
    let totpService: TOTPService

    // MARK: Initialization

    /// Initialize a `ServiceContainer`.
    ///
    /// - Parameters:
    ///   - application: The application instance.
    ///   - appSettingsStore: The service for persisting app settings
    ///   - authenticatorItemRepository: The service to manage items
    ///   - cameraService: The service used by the application to manage camera use.
    ///   - clientService: The service used by the application to handle encryption and decryption tasks.
    ///   - cryptographyService: The service used by the application to encrypt and decrypt items
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - migrationService: The service to do data migrations
    ///   - pasteboardService: The service used by the application for sharing data with other apps.
    ///   - stateService: The service for managing account state.
    ///   - timeProvider: Provides the present time for TOTP Code Calculation.
    ///   - totpService: The service used by the application to validate TOTP keys and produce TOTP values.
    ///
    init(
        application: Application?,
        appSettingsStore: AppSettingsStore,
        authenticatorItemRepository: AuthenticatorItemRepository,
        cameraService: CameraService,
        cryptographyService: CryptographyService,
        clientService: ClientService,
        errorReporter: ErrorReporter,
        migrationService: MigrationService,
        pasteboardService: PasteboardService,
        stateService: StateService,
        timeProvider: TimeProvider,
        totpService: TOTPService
    ) {
        self.application = application
        self.appSettingsStore = appSettingsStore
        self.authenticatorItemRepository = authenticatorItemRepository
        self.cameraService = cameraService
        self.clientService = clientService
        self.cryptographyService = cryptographyService
        self.errorReporter = errorReporter
        self.migrationService = migrationService
        self.pasteboardService = pasteboardService
        self.timeProvider = timeProvider
        self.stateService = stateService
        self.totpService = totpService
    }

    /// A convenience initializer to initialize the `ServiceContainer` with the default services.
    ///
    /// - Parameters:
    ///   - application: The application instance.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///
    public convenience init( // swiftlint:disable:this function_body_length
        application: Application? = nil,
        errorReporter: ErrorReporter
    ) {
        let appSettingsStore = DefaultAppSettingsStore(
            userDefaults: UserDefaults(suiteName: Bundle.main.groupIdentifier)!
        )
        let appIdService = AppIdService(appSettingStore: appSettingsStore)

        let cameraService = DefaultCameraService()
        let clientService = DefaultClientService()
        let dataStore = DataStore(errorReporter: errorReporter)
        let keychainService = DefaultKeychainService()
        let keychainRepository = DefaultKeychainRepository(
            appIdService: appIdService,
            keychainService: keychainService
        )
        let stateService = DefaultStateService(appSettingsStore: appSettingsStore, dataStore: dataStore)
        let timeProvider = CurrentTime()

        let cryptographyKeyService = CryptographyKeyService(
            stateService: stateService
        )

        let cryptographyService = DefaultCryptographyService(
            cryptographyKeyService: cryptographyKeyService
        )

        let migrationService = DefaultMigrationService(
            appSettingsStore: appSettingsStore,
            errorReporter: errorReporter,
            keychainRepository: keychainRepository
        )

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
            appSettingsStore: appSettingsStore,
            authenticatorItemRepository: authenticatorItemRepository,
            cameraService: cameraService,
            cryptographyService: cryptographyService,
            clientService: clientService,
            errorReporter: errorReporter,
            migrationService: migrationService,
            pasteboardService: pasteboardService,
            stateService: stateService,
            timeProvider: timeProvider,
            totpService: totpService
        )
    }
}
