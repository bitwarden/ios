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

    /// The repository to manage biometric unlock policies and access controls the user.
    let biometricsRepository: BiometricsRepository

    /// The service used to obtain device biometrics status & data.
    let biometricsService: BiometricsService

    /// The service used by the application to manage camera use.
    let cameraService: CameraService

    /// The service used by the application to handle encryption and decryption tasks.
    let clientService: ClientService

    /// The service to get locally-specified configuration
    let configService: ConfigService

    /// The service used by the application to encrypt and decrypt items
    let cryptographyService: CryptographyService

    /// The service used by the application to report non-fatal errors.
    let errorReporter: ErrorReporter

    /// The service used to export items.
    let exportItemsService: ExportItemsService

    /// The service used to import items.
    let importItemsService: ImportItemsService

    /// The service used to perform app data migrations.
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
    ///   - biometricsRepository: The repository to manage biometric unlock policies
    ///         and access controls for the user.
    ///   - biometricsService: The service used to obtain device biometrics status & data.
    ///   - cameraService: The service used by the application to manage camera use.
    ///   - clientService: The service used by the application to handle encryption and decryption tasks.
    ///   - configService: The service to get locally-specified configuration.
    ///   - cryptographyService: The service used by the application to encrypt and decrypt items
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - exportItemsService: The service to export items.
    ///   - importItemsService: The service to import items.
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
        biometricsRepository: BiometricsRepository,
        biometricsService: BiometricsService,
        cameraService: CameraService,
        clientService: ClientService,
        configService: ConfigService,
        cryptographyService: CryptographyService,
        errorReporter: ErrorReporter,
        exportItemsService: ExportItemsService,
        importItemsService: ImportItemsService,
        migrationService: MigrationService,
        pasteboardService: PasteboardService,
        stateService: StateService,
        timeProvider: TimeProvider,
        totpService: TOTPService
    ) {
        self.application = application
        self.appSettingsStore = appSettingsStore
        self.authenticatorItemRepository = authenticatorItemRepository
        self.biometricsRepository = biometricsRepository
        self.biometricsService = biometricsService
        self.cameraService = cameraService
        self.clientService = clientService
        self.configService = configService
        self.cryptographyService = cryptographyService
        self.errorReporter = errorReporter
        self.exportItemsService = exportItemsService
        self.importItemsService = importItemsService
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
        let biometricsService = DefaultBiometricsService()
        let cameraService = DefaultCameraService()
        let clientService = DefaultClientService()
        let dataStore = DataStore(errorReporter: errorReporter)
        let keychainService = DefaultKeychainService()

        let keychainRepository = DefaultKeychainRepository(
            appIdService: appIdService,
            keychainService: keychainService
        )

        let stateService = DefaultStateService(
            appSettingsStore: appSettingsStore,
            dataStore: dataStore
        )

        let timeProvider = CurrentTime()

        let biometricsRepository = DefaultBiometricsRepository(
            biometricsService: biometricsService,
            keychainService: keychainRepository,
            stateService: stateService
        )

        let configService = DefaultConfigService(
            errorReporter: errorReporter
        )

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
            cryptographyService: cryptographyService,
            errorReporter: errorReporter,
            timeProvider: timeProvider,
            totpService: totpService
        )

        let exportItemsService = DefaultExportItemsService(
            authenticatorItemRepository: authenticatorItemRepository,
            errorReporter: errorReporter,
            timeProvider: timeProvider
        )

        let importItemsService = DefaultImportItemsService(
            authenticatorItemRepository: authenticatorItemRepository,
            errorReporter: errorReporter
        )

        self.init(
            application: application,
            appSettingsStore: appSettingsStore,
            authenticatorItemRepository: authenticatorItemRepository,
            biometricsRepository: biometricsRepository,
            biometricsService: biometricsService,
            cameraService: cameraService,
            clientService: clientService,
            configService: configService,
            cryptographyService: cryptographyService,
            errorReporter: errorReporter,
            exportItemsService: exportItemsService,
            importItemsService: importItemsService,
            migrationService: migrationService,
            pasteboardService: pasteboardService,
            stateService: stateService,
            timeProvider: timeProvider,
            totpService: totpService
        )
    }
}
