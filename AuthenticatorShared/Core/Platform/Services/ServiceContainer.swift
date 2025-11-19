import AuthenticatorBridgeKit
import BitwardenKit
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

    /// The service used by the application to get info about the app and device it's running on.
    public var appInfoService: any AppInfoService

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
    public let configService: ConfigService

    /// The service used by the application to encrypt and decrypt items
    let cryptographyService: CryptographyService

    /// A helper for building an error report containing the details of an error that occurred.
    public let errorReportBuilder: ErrorReportBuilder

    /// The service used by the application to report non-fatal errors.
    public let errorReporter: ErrorReporter

    /// The service used to export items.
    let exportItemsService: ExportItemsService

    /// The service used by the application for recording temporary debug logs.
    public let flightRecorder: FlightRecorder

    /// The service used to import items.
    let importItemsService: ImportItemsService

    /// The state service that handles language state.
    public let languageStateService: LanguageStateService

    /// The service used to perform app data migrations.
    let migrationService: MigrationService

    /// The service used to receive foreground and background notifications.
    let notificationCenterService: NotificationCenterService

    /// The service used by the application for sharing data with other apps.
    let pasteboardService: PasteboardService

    /// The service used by the application to manage account state.
    let stateService: StateService

    /// Provides the present time for TOTP Code Calculation.
    public let timeProvider: TimeProvider

    /// The factory to create TOTP expiration managers.
    let totpExpirationManagerFactory: TOTPExpirationManagerFactory

    /// The service used by the application to validate TOTP keys and produce TOTP values.
    let totpService: TOTPService

    // MARK: Initialization

    /// Initialize a `ServiceContainer`.
    ///
    /// - Parameters:
    ///   - application: The application instance.
    ///   - appInfoService: The service used by the application to get info about the app and device it's running on.
    ///   - appSettingsStore: The service for persisting app settings
    ///   - authenticatorItemRepository: The service to manage items
    ///   - biometricsRepository: The repository to manage biometric unlock policies
    ///         and access controls for the user.
    ///   - biometricsService: The service used to obtain device biometrics status & data.
    ///   - cameraService: The service used by the application to manage camera use.
    ///   - clientService: The service used by the application to handle encryption and decryption tasks.
    ///   - configService: The service to get locally-specified configuration.
    ///   - cryptographyService: The service used by the application to encrypt and decrypt items
    ///   - errorReportBuilder: A helper for building an error report containing the details of an
    ///     error that occurred.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - exportItemsService: The service to export items.
    ///   - flightRecorder: The service used by the application for recording temporary debug logs.
    ///   - importItemsService: The service to import items.
    ///   - languageStateService: The service for handling language state.
    ///   - migrationService: The service to do data migrations
    ///   - notificationCenterService:  The service used to receive foreground and background notifications.
    ///   - pasteboardService: The service used by the application for sharing data with other apps.
    ///   - stateService: The service for managing account state.
    ///   - timeProvider: Provides the present time for TOTP Code Calculation.
    ///   - totpExpirationManagerFactory: The factory to create TOTP expiration managers.
    ///   - totpService: The service used by the application to validate TOTP keys and produce TOTP values.
    ///
    init(
        application: Application?,
        appInfoService: AppInfoService,
        appSettingsStore: AppSettingsStore,
        authenticatorItemRepository: AuthenticatorItemRepository,
        biometricsRepository: BiometricsRepository,
        biometricsService: BiometricsService,
        cameraService: CameraService,
        clientService: ClientService,
        configService: ConfigService,
        cryptographyService: CryptographyService,
        errorReportBuilder: ErrorReportBuilder,
        errorReporter: ErrorReporter,
        exportItemsService: ExportItemsService,
        flightRecorder: FlightRecorder,
        importItemsService: ImportItemsService,
        languageStateService: LanguageStateService,
        migrationService: MigrationService,
        notificationCenterService: NotificationCenterService,
        pasteboardService: PasteboardService,
        stateService: StateService,
        timeProvider: TimeProvider,
        totpExpirationManagerFactory: TOTPExpirationManagerFactory,
        totpService: TOTPService,
    ) {
        self.application = application
        self.appInfoService = appInfoService
        self.appSettingsStore = appSettingsStore
        self.authenticatorItemRepository = authenticatorItemRepository
        self.biometricsRepository = biometricsRepository
        self.biometricsService = biometricsService
        self.cameraService = cameraService
        self.clientService = clientService
        self.configService = configService
        self.cryptographyService = cryptographyService
        self.errorReportBuilder = errorReportBuilder
        self.errorReporter = errorReporter
        self.exportItemsService = exportItemsService
        self.flightRecorder = flightRecorder
        self.importItemsService = importItemsService
        self.languageStateService = languageStateService
        self.migrationService = migrationService
        self.notificationCenterService = notificationCenterService
        self.pasteboardService = pasteboardService
        self.timeProvider = timeProvider
        self.stateService = stateService
        self.totpExpirationManagerFactory = totpExpirationManagerFactory
        self.totpService = totpService
    }

    /// A convenience initializer to initialize the `ServiceContainer` with the default services.
    ///
    /// - Parameters:
    ///   - application: The application instance.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///
    public convenience init( // swiftlint:disable:this function_body_length
        application: Application,
        errorReporter: ErrorReporter,
    ) {
        let appSettingsStore = DefaultAppSettingsStore(
            userDefaults: UserDefaults(suiteName: Bundle.main.groupIdentifier)!,
        )

        let appIdService = AppIdService(appSettingStore: appSettingsStore)
        let appInfoService = DefaultAppInfoService()

        let biometricsService = DefaultBiometricsService()
        let cameraService = DefaultCameraService()
        let dataStore = DataStore(errorReporter: errorReporter)
        let keychainService = DefaultKeychainService()
        let timeProvider = CurrentTime()

        let keychainRepository = DefaultKeychainRepository(
            appIdService: appIdService,
            keychainService: keychainService,
        )

        let stateService = DefaultStateService(
            appSettingsStore: appSettingsStore,
            dataStore: dataStore,
        )

        let flightRecorder = DefaultFlightRecorder(
            appInfoService: appInfoService,
            errorReporter: errorReporter,
            stateService: stateService,
            timeProvider: timeProvider,
        )
        errorReporter.add(logger: flightRecorder)

        let environmentService = DefaultEnvironmentService()

        let apiService = APIService(
            environmentService: environmentService,
            flightRecorder: flightRecorder,
        )

        let errorReportBuilder = DefaultErrorReportBuilder(
            activeAccountStateProvider: stateService,
            appInfoService: appInfoService,
        )

        let totpExpirationManagerFactory = DefaultTOTPExpirationManagerFactory(timeProvider: timeProvider)

        let biometricsRepository = DefaultBiometricsRepository(
            biometricsService: biometricsService,
            keychainService: keychainRepository,
            stateService: stateService,
        )

        let configService = DefaultConfigService(
            appSettingsStore: appSettingsStore,
            configApiService: apiService,
            errorReporter: errorReporter,
            stateService: stateService,
            timeProvider: timeProvider,
        )

        let clientBuilder = DefaultClientBuilder(errorReporter: errorReporter)
        let clientService = DefaultClientService(
            clientBuilder: clientBuilder,
            configService: configService,
            errorReporter: errorReporter,
            stateService: stateService,
        )

        let cryptographyKeyService = CryptographyKeyService(
            stateService: stateService,
        )

        let cryptographyService = DefaultCryptographyService(
            cryptographyKeyService: cryptographyKeyService,
        )

        let migrationService = DefaultMigrationService(
            appSettingsStore: appSettingsStore,
            errorReporter: errorReporter,
            keychainRepository: keychainRepository,
        )

        let notificationCenterService = DefaultNotificationCenterService()

        let totpService = DefaultTOTPService(
            clientService: clientService,
            errorReporter: errorReporter,
            timeProvider: timeProvider,
        )

        let pasteboardService = DefaultPasteboardService(
            errorReporter: errorReporter,
        )

        let authenticatorItemService = DefaultAuthenticatorItemService(
            authenticatorItemDataStore: dataStore,
        )

        let sharedKeychainStorage = DefaultSharedKeychainStorage(
            keychainService: keychainService,
            sharedAppGroupIdentifier: Bundle.main.sharedAppGroupIdentifier,
        )

        let sharedKeychainRepository = DefaultSharedKeychainRepository(
            storage: sharedKeychainStorage,
        )

        let sharedCryptographyService = DefaultAuthenticatorCryptographyService(
            sharedKeychainRepository: sharedKeychainRepository,
        )

        let sharedDataStore = AuthenticatorBridgeDataStore(
            errorReporter: errorReporter,
            groupIdentifier: Bundle.main.sharedAppGroupIdentifier,
            storeType: .persisted,
        )

        let sharedTimeoutService = DefaultSharedTimeoutService(
            sharedKeychainRepository: sharedKeychainRepository,
            timeProvider: timeProvider,
        )

        let sharedItemService = DefaultAuthenticatorBridgeItemService(
            cryptoService: sharedCryptographyService,
            dataStore: sharedDataStore,
            sharedKeychainRepository: sharedKeychainRepository,
            sharedTimeoutService: sharedTimeoutService,
        )

        let authenticatorItemRepository = DefaultAuthenticatorItemRepository(
            application: application,
            authenticatorItemService: authenticatorItemService,
            configService: configService,
            cryptographyService: cryptographyService,
            errorReporter: errorReporter,
            sharedItemService: sharedItemService,
            timeProvider: timeProvider,
            totpService: totpService,
        )

        let exportItemsService = DefaultExportItemsService(
            authenticatorItemRepository: authenticatorItemRepository,
            errorReporter: errorReporter,
            timeProvider: timeProvider,
        )

        let importItemsService = DefaultImportItemsService(
            authenticatorItemRepository: authenticatorItemRepository,
            errorReporter: errorReporter,
        )

        self.init(
            application: application,
            appInfoService: appInfoService,
            appSettingsStore: appSettingsStore,
            authenticatorItemRepository: authenticatorItemRepository,
            biometricsRepository: biometricsRepository,
            biometricsService: biometricsService,
            cameraService: cameraService,
            clientService: clientService,
            configService: configService,
            cryptographyService: cryptographyService,
            errorReportBuilder: errorReportBuilder,
            errorReporter: errorReporter,
            exportItemsService: exportItemsService,
            flightRecorder: flightRecorder,
            importItemsService: importItemsService,
            languageStateService: stateService,
            migrationService: migrationService,
            notificationCenterService: notificationCenterService,
            pasteboardService: pasteboardService,
            stateService: stateService,
            timeProvider: timeProvider,
            totpExpirationManagerFactory: totpExpirationManagerFactory,
            totpService: totpService,
        )
    }
}
