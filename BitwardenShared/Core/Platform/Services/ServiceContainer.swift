import AuthenticatorBridgeKit
import BitwardenKit
import BitwardenSdk
import UIKit

// swiftlint:disable file_length

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
public class ServiceContainer: Services { // swiftlint:disable:this type_body_length
    // MARK: Static properties

    /// The singleton instance of the `ServiceContainer`.
    private static var sharedInstance: ServiceContainer?

    // MARK: Properties

    /// The service used by the application to make API requests.
    let apiService: APIService

    /// Helper used to know app context.
    let appContextHelper: AppContextHelper

    /// The service used by the application to manage the app's ID.
    let appIdService: AppIdService

    /// The service used by the application to get info about the app and device it's running on.
    let appInfoService: AppInfoService

    /// The application instance (i.e. `UIApplication`), if the app isn't running in an extension.
    let application: Application?

    /// The service used by the application to persist app setting values.
    let appSettingsStore: AppSettingsStore

    /// The repository used by the application to manage auth data for the UI layer.
    let authRepository: AuthRepository

    /// The service used by the application to handle authentication tasks.
    let authService: AuthService

    /// The service used by the application to sync TOTP codes with the Authenticator app.
    let authenticatorSyncService: AuthenticatorSyncService?

    /// The service which manages the ciphers exposed to the system for AutoFill suggestions.
    let autofillCredentialService: AutofillCredentialService

    /// The repository to manage biometric unlock policies and access controls the user.
    let biometricsRepository: BiometricsRepository

    /// The service used to obtain device biometrics status & data.
    let biometricsService: BiometricsService

    /// The service used by the application to generate captcha related artifacts.
    let captchaService: CaptchaService

    /// The service used by the application to manage camera use.
    let cameraService: CameraService

    /// The service used by the application to handle encryption and decryption tasks.
    let clientService: ClientService

    /// The service to get server-specified configuration
    let configService: ConfigService

    /// The service used by the application to manage the environment settings.
    let environmentService: EnvironmentService

    /// A helper for building an error report containing the details of an error that occurred.
    let errorReportBuilder: ErrorReportBuilder

    /// The service used by the application to report non-fatal errors.
    let errorReporter: ErrorReporter

    /// The service used to record and send events.
    let eventService: EventService

    /// The repository to handle exporting ciphers in Credential Exchange Format
    let exportCXFCiphersRepository: ExportCXFCiphersRepository

    /// The service used to export a vault.
    let exportVaultService: ExportVaultService

    /// A store to be used on Fido2 flows to get/save credentials.
    let fido2CredentialStore: Fido2CredentialStore

    /// A helper to be used on Fido2 flows that requires user interaction and extends the capabilities
    /// of the `Fido2UserInterface` from the SDK.
    let fido2UserInterfaceHelper: Fido2UserInterfaceHelper

    /// The service used by the application for recording temporary debug logs.
    let flightRecorder: FlightRecorder

    /// The repository used by the application to manage generator data for the UI layer.
    let generatorRepository: GeneratorRepository

    /// The repository used by the application to manage importing credential in Credential Exhange flow.
    let importCiphersRepository: ImportCiphersRepository

    /// The service used to access & store data on the device keychain.
    let keychainService: KeychainService

    /// The repository used to manage keychain items.
    let keychainRepository: KeychainRepository

    /// The service used by the application to evaluate local auth policies.
    let localAuthService: LocalAuthService

    /// The serviced used to perform app data migrations.
    let migrationService: MigrationService

    /// The service used by the application to read NFC tags.
    let nfcReaderService: NFCReaderService

    /// The service used by the application to access the system's notification center.
    let notificationCenterService: NotificationCenterService

    /// The service used by the application to handle notifications.
    let notificationService: NotificationService

    /// The service used by the application for sharing data with other apps.
    let pasteboardService: PasteboardService

    /// The mediator to execute pending `AppIntent` actions.
    let pendingAppIntentActionMediator: PendingAppIntentActionMediator

    /// The service for managing the polices for the user.
    let policyService: PolicyService

    /// The helper used for app rehydration.
    let rehydrationHelper: RehydrationHelper

    /// The service used by the appllication to manage app review prompts related data.
    let reviewPromptService: ReviewPromptService

    /// The repository used by the application to manage send data for the UI layer.
    public let sendRepository: SendRepository

    /// The repository used by the application to manage data for the UI layer.
    let settingsRepository: SettingsRepository

    /// The service that manages account timeout between apps.
    public let sharedTimeoutService: SharedTimeoutService

    /// The service used by the application to manage account state.
    let stateService: StateService

    /// The service used to handle syncing vault data with the API.
    let syncService: SyncService

    /// The object used by the application to retrieve information about this device.
    let systemDevice: SystemDevice

    /// Factory to create `TextAutofillHelper`s.
    let textAutofillHelperFactory: TextAutofillHelperFactory

    /// Provides the present time for TOTP Code Calculation.
    let timeProvider: TimeProvider

    /// The service used by the application to manage account access tokens.
    let tokenService: TokenService

    /// The factory to create TOTP expiration managers.
    let totpExpirationManagerFactory: TOTPExpirationManagerFactory

    /// The service used by the application to validate TOTP keys and produce TOTP values.
    let totpService: TOTPService

    /// A service used to handle device trust.
    let trustDeviceService: TrustDeviceService

    /// The service used by the application to generate a two step login URL.
    let twoStepLoginService: TwoStepLoginService

    /// A factory protocol to create `UserVerificationHelper`s.
    let userVerificationHelperFactory: UserVerificationHelperFactory

    /// The repository used by the application to manage vault data for the UI layer.
    let vaultRepository: VaultRepository

    /// The service used by the application to manage vault access.
    let vaultTimeoutService: VaultTimeoutService

    /// The service used by the application to connect to and communicate with the watch app.
    let watchService: WatchService

    // MARK: Initialization

    /// Initialize a `ServiceContainer`.
    ///
    /// - Parameters:
    ///   - apiService: The service used by the application to make API requests.
    ///   - appContextHelper: The helper used to know app context.
    ///   - appIdService: The service used by the application to manage the app's ID.
    ///   - appInfoService: The service used by the application to get info about the app and device
    ///     it's running on.
    ///   - application: The application instance.
    ///   - appSettingsStore: The service used by the application to persist app setting values.
    ///   - authRepository: The repository used by the application to manage auth data for the UI layer.
    ///   - authService: The service used by the application to handle authentication tasks.
    ///   - authenticatorSyncService: The service used by the application to sync TOTP codes with the Authenticator app.
    ///   - autofillCredentialService: The service which manages the ciphers exposed to the system
    ///     for AutoFill suggestions.
    ///   - biometricsRepository: The repository to manage biometric unlock policies and access
    ///     controls for the user.
    ///   - biometricsService: The service used to obtain device biometrics status & data.
    ///   - captchaService: The service used by the application to create captcha related artifacts.
    ///   - cameraService: The service used by the application to manage camera use.
    ///   - clientService: The service used by the application to handle encryption and decryption tasks.
    ///   - configService: The service to get server-specified configuration.
    ///   - environmentService: The service used by the application to manage the environment settings.
    ///   - errorReportBuilder: A helper for building an error report containing the details of an
    ///     error that occurred.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - eventService: The service used to record and send events.
    ///   - exportCXFCiphersRepository: The repository to handle exporting ciphers in Credential Exchange Format.
    ///   - exportVaultService: The service used to export vaults.
    ///   - fido2UserInterfaceHelper: A helper to be used on Fido2 flows that requires user interaction
    ///   and extends the capabilities of the `Fido2UserInterface` from the SDK.
    ///   - fido2CredentialStore: A store to be used on Fido2 flows to get/save credentials.
    ///   - flightRecorder: The service used by the application for recording temporary debug logs.
    ///   - generatorRepository: The repository used by the application to manage generator data for the UI layer.
    ///   - importCiphersRepository: The repository used by the application to manage importing credential
    ///   in Credential Exhange flow.
    ///   - keychainRepository: The repository used to manages keychain items.
    ///   - keychainService: The service used to access & store data on the device keychain.
    ///   - localAuthService: The service used by the application to evaluate local auth policies.
    ///   - migrationService: The serviced used to perform app data migrations.
    ///   - nfcReaderService: The service used by the application to read NFC tags.
    ///   - notificationCenterService: The service used by the application to access the system's notification center.
    ///   - notificationService: The service used by the application to handle notifications.
    ///   - pasteboardService: The service used by the application for sharing data with other apps.
    ///   - rehydrationHelper: The helper used for app rehydration.
    ///   - reviewPromptService: The service used by the application to manage app review prompts related data.
    ///   - pendingAppIntentActionMediator: The mediator to execute pending `AppIntent` actions.
    ///   - policyService: The service for managing the polices for the user.
    ///   - sendRepository: The repository used by the application to manage send data for the UI layer.
    ///   - settingsRepository: The repository used by the application to manage data for the UI layer.
    ///   - sharedTimeoutService: The service that manages account timeout between apps.
    ///   - stateService: The service used by the application to manage account state.
    ///   - syncService: The service used to handle syncing vault data with the API.
    ///   - systemDevice: The object used by the application to retrieve information about this device.
    ///   - textAutofillHelperFactory: Factory to create `TextAutofillHelper`s.
    ///   - timeProvider: Provides the present time for TOTP Code Calculation.
    ///   - tokenService: The service used by the application to manage account access tokens.
    ///   - totpExpirationManagerFactory: The factory to create TOTP expiration managers.
    ///   - totpService: The service used by the application to validate TOTP keys and produce TOTP values.
    ///   - trustDeviceService: The service used to handle device trust.
    ///   - twoStepLoginService: The service used by the application to generate a two step login URL.
    ///   - vaultRepository: The repository used by the application to manage vault data for the UI layer.
    ///   - vaultTimeoutService: The service used by the application to manage vault access.
    ///   - watchService: The service used by the application to connect to and communicate with the watch app.
    ///
    @MainActor
    init( // swiftlint:disable:this function_body_length
        apiService: APIService,
        appContextHelper: AppContextHelper,
        appIdService: AppIdService,
        appInfoService: AppInfoService,
        application: Application?,
        appSettingsStore: AppSettingsStore,
        authRepository: AuthRepository,
        authService: AuthService,
        authenticatorSyncService: AuthenticatorSyncService,
        autofillCredentialService: AutofillCredentialService,
        biometricsRepository: BiometricsRepository,
        biometricsService: BiometricsService,
        captchaService: CaptchaService,
        cameraService: CameraService,
        clientService: ClientService,
        configService: ConfigService,
        environmentService: EnvironmentService,
        errorReportBuilder: ErrorReportBuilder,
        errorReporter: ErrorReporter,
        eventService: EventService,
        exportCXFCiphersRepository: ExportCXFCiphersRepository,
        exportVaultService: ExportVaultService,
        fido2CredentialStore: Fido2CredentialStore,
        fido2UserInterfaceHelper: Fido2UserInterfaceHelper,
        flightRecorder: FlightRecorder,
        generatorRepository: GeneratorRepository,
        importCiphersRepository: ImportCiphersRepository,
        keychainRepository: KeychainRepository,
        keychainService: KeychainService,
        localAuthService: LocalAuthService,
        migrationService: MigrationService,
        nfcReaderService: NFCReaderService,
        notificationCenterService: NotificationCenterService,
        notificationService: NotificationService,
        pasteboardService: PasteboardService,
        pendingAppIntentActionMediator: PendingAppIntentActionMediator,
        policyService: PolicyService,
        rehydrationHelper: RehydrationHelper,
        reviewPromptService: ReviewPromptService,
        sendRepository: SendRepository,
        settingsRepository: SettingsRepository,
        sharedTimeoutService: SharedTimeoutService,
        stateService: StateService,
        syncService: SyncService,
        systemDevice: SystemDevice,
        textAutofillHelperFactory: TextAutofillHelperFactory,
        timeProvider: TimeProvider,
        tokenService: TokenService,
        totpExpirationManagerFactory: TOTPExpirationManagerFactory,
        totpService: TOTPService,
        trustDeviceService: TrustDeviceService,
        twoStepLoginService: TwoStepLoginService,
        userVerificationHelperFactory: UserVerificationHelperFactory,
        vaultRepository: VaultRepository,
        vaultTimeoutService: VaultTimeoutService,
        watchService: WatchService
    ) {
        self.apiService = apiService
        self.appContextHelper = appContextHelper
        self.appIdService = appIdService
        self.appInfoService = appInfoService
        self.application = application
        self.appSettingsStore = appSettingsStore
        self.authRepository = authRepository
        self.authService = authService
        self.authenticatorSyncService = authenticatorSyncService
        self.autofillCredentialService = autofillCredentialService
        self.biometricsRepository = biometricsRepository
        self.biometricsService = biometricsService
        self.captchaService = captchaService
        self.cameraService = cameraService
        self.clientService = clientService
        self.configService = configService
        self.environmentService = environmentService
        self.errorReportBuilder = errorReportBuilder
        self.errorReporter = errorReporter
        self.eventService = eventService
        self.exportCXFCiphersRepository = exportCXFCiphersRepository
        self.exportVaultService = exportVaultService
        self.fido2CredentialStore = fido2CredentialStore
        self.fido2UserInterfaceHelper = fido2UserInterfaceHelper
        self.flightRecorder = flightRecorder
        self.generatorRepository = generatorRepository
        self.importCiphersRepository = importCiphersRepository
        self.keychainService = keychainService
        self.keychainRepository = keychainRepository
        self.localAuthService = localAuthService
        self.migrationService = migrationService
        self.nfcReaderService = nfcReaderService
        self.notificationCenterService = notificationCenterService
        self.notificationService = notificationService
        self.pasteboardService = pasteboardService
        self.pendingAppIntentActionMediator = pendingAppIntentActionMediator
        self.policyService = policyService
        self.rehydrationHelper = rehydrationHelper
        self.reviewPromptService = reviewPromptService
        self.sendRepository = sendRepository
        self.settingsRepository = settingsRepository
        self.sharedTimeoutService = sharedTimeoutService
        self.stateService = stateService
        self.syncService = syncService
        self.systemDevice = systemDevice
        self.textAutofillHelperFactory = textAutofillHelperFactory
        self.timeProvider = timeProvider
        self.tokenService = tokenService
        self.totpExpirationManagerFactory = totpExpirationManagerFactory
        self.totpService = totpService
        self.trustDeviceService = trustDeviceService
        self.twoStepLoginService = twoStepLoginService
        self.userVerificationHelperFactory = userVerificationHelperFactory
        self.vaultRepository = vaultRepository
        self.vaultTimeoutService = vaultTimeoutService
        self.watchService = watchService
    }

    /// A convenience initializer to initialize the `ServiceContainer` with the default services.
    ///
    /// - Parameters:
    ///   - appContext: The context in which the app is running.
    ///   - application: The application instance.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - nfcReaderService: The service used by the application to read NFC tags.
    ///
    @MainActor
    public convenience init( // swiftlint:disable:this function_body_length
        appContext: AppContext = .mainApp,
        application: Application? = nil,
        errorReporter: ErrorReporter,
        nfcReaderService: NFCReaderService? = nil
    ) {
        let appContextHelper = DefaultAppContextHelper(appContext: appContext)
        let appSettingsStore = DefaultAppSettingsStore(
            userDefaults: UserDefaults(suiteName: Bundle.main.groupIdentifier)!
        )
        let appIdService = AppIdService(appSettingStore: appSettingsStore)
        let appInfoService = DefaultAppInfoService()

        let dataStore = DataStore(errorReporter: errorReporter)

        let keychainService = DefaultKeychainService()

        let keychainRepository = DefaultKeychainRepository(
            appIdService: appIdService,
            keychainService: keychainService
        )
        let timeProvider = CurrentTime()

        let totpExpirationManagerFactory = DefaultTOTPExpirationManagerFactory(timeProvider: timeProvider)

        let stateService = DefaultStateService(
            appSettingsStore: appSettingsStore,
            dataStore: dataStore,
            errorReporter: errorReporter,
            keychainRepository: keychainRepository
        )

        let flightRecorder = DefaultFlightRecorder(
            appInfoService: appInfoService,
            errorReporter: errorReporter,
            stateService: stateService,
            timeProvider: timeProvider
        )
        errorReporter.add(logger: flightRecorder)

        let rehydrationHelper = DefaultRehydrationHelper(
            errorReporter: errorReporter,
            stateService: stateService,
            timeProvider: timeProvider
        )

        let environmentService = DefaultEnvironmentService(errorReporter: errorReporter, stateService: stateService)
        let collectionService = DefaultCollectionService(collectionDataStore: dataStore, stateService: stateService)
        let settingsService = DefaultSettingsService(settingsDataStore: dataStore, stateService: stateService)
        let tokenService = DefaultTokenService(keychainRepository: keychainRepository, stateService: stateService)
        let apiService = APIService(
            environmentService: environmentService,
            flightRecorder: flightRecorder,
            stateService: stateService,
            tokenService: tokenService
        )
        let errorReportBuilder = DefaultErrorReportBuilder(
            appInfoService: appInfoService,
            stateService: stateService
        )

        let configService = DefaultConfigService(
            appSettingsStore: appSettingsStore,
            configApiService: apiService,
            errorReporter: errorReporter,
            stateService: stateService,
            timeProvider: timeProvider
        )

        let cipherService = DefaultCipherService(
            cipherAPIService: apiService,
            cipherDataStore: dataStore,
            fileAPIService: apiService,
            stateService: stateService
        )

        let clientBuilder = DefaultClientBuilder(
            errorReporter: errorReporter
        )
        let clientService = DefaultClientService(
            clientBuilder: clientBuilder,
            configService: configService,
            errorReporter: errorReporter,
            sdkRepositoryFactory: DefaultSdkRepositoryFactory(
                cipherDataStore: dataStore,
                errorReporter: errorReporter
            ),
            stateService: stateService
        )

        let biometricsService = DefaultBiometricsService()
        let biometricsRepository = DefaultBiometricsRepository(
            biometricsService: biometricsService,
            keychainService: keychainRepository,
            stateService: stateService
        )

        let localAuthService = DefaultLocalAuthService()

        let captchaService = DefaultCaptchaService(environmentService: environmentService, stateService: stateService)
        let notificationCenterService = DefaultNotificationCenterService()

        let folderService = DefaultFolderService(
            folderAPIService: apiService,
            folderDataStore: dataStore,
            stateService: stateService
        )

        let organizationService = DefaultOrganizationService(
            clientService: clientService,
            errorReporter: errorReporter,
            organizationDataStore: dataStore,
            stateService: stateService
        )

        let policyService = DefaultPolicyService(
            configService: configService,
            organizationService: organizationService,
            policyDataStore: dataStore,
            stateService: stateService
        )

        let eventService = DefaultEventService(
            cipherService: cipherService,
            errorReporter: errorReporter,
            eventAPIService: apiService,
            organizationService: organizationService,
            stateService: stateService,
            timeProvider: timeProvider
        )

        let exportVaultService = DefultExportVaultService(
            cipherService: cipherService,
            clientService: clientService,
            errorReporter: errorReporter,
            folderService: folderService,
            policyService: policyService,
            stateService: stateService,
            timeProvider: timeProvider,
        )

        let sendService = DefaultSendService(
            fileAPIService: apiService,
            sendAPIService: apiService,
            sendDataStore: dataStore,
            stateService: stateService
        )

        let watchService = DefaultWatchService(
            cipherService: cipherService,
            clientService: clientService,
            environmentService: environmentService,
            errorReporter: errorReporter,
            organizationService: organizationService,
            stateService: stateService
        )

        let keyConnectorService = DefaultKeyConnectorService(
            accountAPIService: apiService,
            clientService: clientService,
            keyConnectorAPIService: apiService,
            organizationService: organizationService,
            stateService: stateService,
            tokenService: tokenService
        )

        let sharedKeychainStorage = DefaultSharedKeychainStorage(
            keychainService: keychainService,
            sharedAppGroupIdentifier: Bundle.main.sharedAppGroupIdentifier
        )

        let sharedKeychainRepository = DefaultSharedKeychainRepository(
            storage: sharedKeychainStorage
        )

        let sharedTimeoutService = DefaultSharedTimeoutService(
            sharedKeychainRepository: sharedKeychainRepository,
            timeProvider: timeProvider
        )

        let vaultTimeoutService = DefaultVaultTimeoutService(
            biometricsRepository: biometricsRepository,
            clientService: clientService,
            errorReporter: errorReporter,
            sharedTimeoutService: sharedTimeoutService,
            stateService: stateService,
            timeProvider: timeProvider
        )

        let reviewPromptService = DefaultReviewPromptService(
            appVersion: Bundle.main.appVersion,
            stateService: stateService
        )

        let syncService = DefaultSyncService(
            accountAPIService: apiService,
            cipherService: cipherService,
            clientService: clientService,
            collectionService: collectionService,
            folderService: folderService,
            keyConnectorService: keyConnectorService,
            organizationService: organizationService,
            policyService: policyService,
            sendService: sendService,
            settingsService: settingsService,
            stateService: stateService,
            syncAPIService: apiService,
            timeProvider: timeProvider,
            vaultTimeoutService: vaultTimeoutService
        )

        let trustDeviceService = DefaultTrustDeviceService(
            appIdService: appIdService,
            authAPIService: apiService,
            clientService: clientService,
            keychainRepository: keychainRepository,
            stateService: stateService
        )

        let twoStepLoginService = DefaultTwoStepLoginService(environmentService: environmentService)

        let pasteboardService = DefaultPasteboardService(
            errorReporter: errorReporter,
            stateService: stateService
        )

        let totpService = DefaultTOTPService(
            clientService: clientService,
            pasteboardService: pasteboardService,
            stateService: stateService
        )

        let authService = DefaultAuthService(
            accountAPIService: apiService,
            appIdService: appIdService,
            authAPIService: apiService,
            clientService: clientService,
            configService: configService,
            environmentService: environmentService,
            errorReporter: errorReporter,
            keychainRepository: keychainRepository,
            policyService: policyService,
            stateService: stateService,
            systemDevice: UIDevice.current,
            trustDeviceService: trustDeviceService
        )

        let authRepository = DefaultAuthRepository(
            accountAPIService: apiService,
            appContextHelper: appContextHelper,
            authService: authService,
            biometricsRepository: biometricsRepository,
            clientService: clientService,
            configService: configService,
            environmentService: environmentService,
            errorReporter: errorReporter,
            keychainService: keychainRepository,
            keyConnectorService: keyConnectorService,
            organizationAPIService: apiService,
            organizationService: organizationService,
            organizationUserAPIService: apiService,
            policyService: policyService,
            stateService: stateService,
            trustDeviceService: trustDeviceService,
            vaultTimeoutService: vaultTimeoutService
        )

        let pendingAppIntentActionMediator = DefaultPendingAppIntentActionMediator(
            authRepository: authRepository,
            errorReporter: errorReporter,
            stateService: stateService
        )

        let migrationService = DefaultMigrationService(
            appGroupUserDefaults: UserDefaults(suiteName: Bundle.main.groupIdentifier)!,
            appSettingsStore: appSettingsStore,
            errorReporter: errorReporter,
            keychainRepository: keychainRepository,
            keychainService: keychainService
        )

        let notificationService = DefaultNotificationService(
            appIdService: appIdService,
            authRepository: authRepository,
            authService: authService,
            errorReporter: errorReporter,
            notificationAPIService: apiService,
            stateService: stateService,
            syncService: syncService
        )

        let generatorRepository = DefaultGeneratorRepository(
            clientService: clientService,
            dataStore: dataStore,
            stateService: stateService
        )

        let sendRepository = DefaultSendRepository(
            clientService: clientService,
            environmentService: environmentService,
            organizationService: organizationService,
            sendService: sendService,
            stateService: stateService,
            syncService: syncService
        )

        let settingsRepository = DefaultSettingsRepository(
            clientService: clientService,
            folderService: folderService,
            pasteboardService: pasteboardService,
            stateService: stateService,
            syncService: syncService,
            vaultTimeoutService: vaultTimeoutService
        )

        let vaultListDirectorStrategyFactory = DefaultVaultListDirectorStrategyFactory(
            cipherService: cipherService,
            collectionService: collectionService,
            folderService: folderService,
            vaultListBuilderFactory: DefaultVaultListSectionsBuilderFactory(
                clientService: clientService,
                errorReporter: errorReporter
            ),
            vaultListDataPreparator: DefaultVaultListDataPreparator(
                cipherMatchingHelperFactory: DefaultCipherMatchingHelperFactory(
                    settingsService: settingsService,
                    stateService: stateService
                ),
                ciphersClientWrapperService: DefaultCiphersClientWrapperService(
                    clientService: clientService,
                    errorReporter: errorReporter
                ),
                clientService: clientService,
                configService: configService,
                errorReporter: errorReporter,
                policyService: policyService,
                stateService: stateService,
                vaultListPreparedDataBuilderFactory: DefaultVaultListPreparedDataBuilderFactory(
                    clientService: clientService,
                    errorReporter: errorReporter,
                    stateService: stateService,
                    timeProvider: timeProvider
                )
            )
        )

        let vaultRepository = DefaultVaultRepository(
            cipherService: cipherService,
            clientService: clientService,
            collectionService: collectionService,
            configService: configService,
            environmentService: environmentService,
            errorReporter: errorReporter,
            folderService: folderService,
            organizationService: organizationService,
            policyService: policyService,
            settingsService: settingsService,
            stateService: stateService,
            syncService: syncService,
            timeProvider: timeProvider,
            vaultListDirectorStrategyFactory: vaultListDirectorStrategyFactory,
            vaultTimeoutService: vaultTimeoutService
        )

        let fido2UserInterfaceHelper = DefaultFido2UserInterfaceHelper(
            fido2UserVerificationMediator: DefaultFido2UserVerificationMediator(
                authRepository: authRepository,
                stateService: stateService,
                userVerificationHelper: DefaultUserVerificationHelper(
                    authRepository: authRepository,
                    errorReporter: errorReporter,
                    localAuthService: localAuthService
                ),
                userVerificationRunner: DefaultUserVerificationRunner()
            )
        )

        #if DEBUG
        let fido2CredentialStore = DebuggingFido2CredentialStoreService(
            fido2CredentialStore: Fido2CredentialStoreService(
                cipherService: cipherService,
                clientService: clientService,
                errorReporter: errorReporter,
                syncService: syncService
            )
        )
        #else
        let fido2CredentialStore = Fido2CredentialStoreService(
            cipherService: cipherService,
            clientService: clientService,
            errorReporter: errorReporter,
            syncService: syncService
        )
        #endif

        let credentialIdentityFactory = DefaultCredentialIdentityFactory()
        let autofillCredentialService = DefaultAutofillCredentialService(
            cipherService: cipherService,
            clientService: clientService,
            credentialIdentityFactory: credentialIdentityFactory,
            errorReporter: errorReporter,
            eventService: eventService,
            fido2CredentialStore: fido2CredentialStore,
            fido2UserInterfaceHelper: fido2UserInterfaceHelper,
            pasteboardService: pasteboardService,
            stateService: stateService,
            timeProvider: timeProvider,
            totpService: totpService,
            vaultTimeoutService: vaultTimeoutService
        )

        let credentialManagerFactory = DefaultCredentialManagerFactory()
        let cxfCredentialsResultBuilder = DefaultCXFCredentialsResultBuilder()

        let importCiphersRepository = DefaultImportCiphersRepository(
            clientService: clientService,
            credentialManagerFactory: credentialManagerFactory,
            cxfCredentialsResultBuilder: cxfCredentialsResultBuilder,
            importCiphersService: DefaultImportCiphersService(
                importCiphersAPIService: apiService
            ),
            syncService: syncService
        )

        let exportCXFCiphersRepository = DefaultExportCXFCiphersRepository(
            cipherService: cipherService,
            clientService: clientService,
            credentialManagerFactory: credentialManagerFactory,
            cxfCredentialsResultBuilder: cxfCredentialsResultBuilder,
            errorReporter: errorReporter,
            stateService: stateService
        )

        let userVerificationHelperFactory = DefaultUserVerificationHelperFactory(
            authRepository: authRepository,
            errorReporter: errorReporter,
            localAuthService: localAuthService
        )

        let textAutofillHelperFactory = DefaultTextAutofillHelperFactory(
            authRepository: authRepository,
            errorReporter: errorReporter,
            eventService: eventService,
            userVerificationHelperFactory: userVerificationHelperFactory,
            vaultRepository: vaultRepository
        )

        let authenticatorDataStore = AuthenticatorBridgeDataStore(
            errorReporter: errorReporter,
            groupIdentifier: Bundle.main.sharedAppGroupIdentifier,
            storeType: .persisted
        )

        let sharedCryptographyService = DefaultAuthenticatorCryptographyService(
            sharedKeychainRepository: sharedKeychainRepository
        )

        let authBridgeItemService = DefaultAuthenticatorBridgeItemService(
            cryptoService: sharedCryptographyService,
            dataStore: authenticatorDataStore,
            sharedKeychainRepository: sharedKeychainRepository,
            sharedTimeoutService: sharedTimeoutService
        )

        // Note: `DefaultAuthenticatorSyncService` gets it's own `ClientService` that's separate
        // from what the rest of the app uses. That ensures its vault unlock and syncing doesn't
        // affect anything outside of authenticator syncing.
        let authenticatorClientService = DefaultClientService(
            clientBuilder: clientBuilder,
            configService: configService,
            errorReporter: errorReporter,
            sdkRepositoryFactory: DefaultSdkRepositoryFactory(
                cipherDataStore: dataStore,
                errorReporter: errorReporter
            ),
            stateService: stateService
        )
        let authenticatorSyncService = DefaultAuthenticatorSyncService(
            authBridgeItemService: authBridgeItemService,
            authenticatorClientService: authenticatorClientService,
            cipherDataStore: dataStore,
            clientService: clientService,
            configService: configService,
            errorReporter: errorReporter,
            keychainRepository: keychainRepository,
            organizationService: organizationService,
            sharedKeychainRepository: sharedKeychainRepository,
            stateService: stateService,
            vaultTimeoutService: vaultTimeoutService
        )
        Task { await authenticatorSyncService.start() }

        self.init(
            apiService: apiService,
            appContextHelper: appContextHelper,
            appIdService: appIdService,
            appInfoService: appInfoService,
            application: application,
            appSettingsStore: appSettingsStore,
            authRepository: authRepository,
            authService: authService,
            authenticatorSyncService: authenticatorSyncService,
            autofillCredentialService: autofillCredentialService,
            biometricsRepository: biometricsRepository,
            biometricsService: biometricsService,
            captchaService: captchaService,
            cameraService: DefaultCameraService(),
            clientService: clientService,
            configService: configService,
            environmentService: environmentService,
            errorReportBuilder: errorReportBuilder,
            errorReporter: errorReporter,
            eventService: eventService,
            exportCXFCiphersRepository: exportCXFCiphersRepository,
            exportVaultService: exportVaultService,
            fido2CredentialStore: fido2CredentialStore,
            fido2UserInterfaceHelper: fido2UserInterfaceHelper,
            flightRecorder: flightRecorder,
            generatorRepository: generatorRepository,
            importCiphersRepository: importCiphersRepository,
            keychainRepository: keychainRepository,
            keychainService: keychainService,
            localAuthService: localAuthService,
            migrationService: migrationService,
            nfcReaderService: nfcReaderService ?? NoopNFCReaderService(),
            notificationCenterService: notificationCenterService,
            notificationService: notificationService,
            pasteboardService: pasteboardService,
            pendingAppIntentActionMediator: pendingAppIntentActionMediator,
            policyService: policyService,
            rehydrationHelper: rehydrationHelper,
            reviewPromptService: reviewPromptService,
            sendRepository: sendRepository,
            settingsRepository: settingsRepository,
            sharedTimeoutService: sharedTimeoutService,
            stateService: stateService,
            syncService: syncService,
            systemDevice: UIDevice.current,
            textAutofillHelperFactory: textAutofillHelperFactory,
            timeProvider: timeProvider,
            tokenService: tokenService,
            totpExpirationManagerFactory: totpExpirationManagerFactory,
            totpService: totpService,
            trustDeviceService: trustDeviceService,
            twoStepLoginService: twoStepLoginService,
            userVerificationHelperFactory: userVerificationHelperFactory,
            vaultRepository: vaultRepository,
            vaultTimeoutService: vaultTimeoutService,
            watchService: watchService
        )
    }

    // MARK: Static methods

    /// Creates a singleton instance of the `ServiceContainer` or returns one if it has already been created.
    /// - Parameters:
    ///   - appContext: The context in which the app is running.
    ///   - application: The application instance.
    ///   - errorReporter: The closure to get a service used by the application to report non-fatal errors.
    ///   - nfcReaderService: The closure to get a service used by the application to read NFC tags.
    /// - Returns: Singleton `ServiceContainer`.
    @MainActor
    public static func shared(
        appContext: AppContext = .mainApp,
        application: Application? = nil,
        errorReporter: () -> ErrorReporter,
        nfcReaderService: () -> NFCReaderService? = { nil }
    ) -> ServiceContainer {
        if let sharedInstance {
            return sharedInstance
        }

        let serviceContainer = ServiceContainer(
            appContext: appContext,
            application: application,
            errorReporter: errorReporter(),
            nfcReaderService: nfcReaderService()
        )
        sharedInstance = serviceContainer
        return serviceContainer
    }
}

extension ServiceContainer {
    // MARK: Properties

    var accountAPIService: AccountAPIService {
        apiService
    }

    var authAPIService: AuthAPIService {
        apiService
    }

    var configAPIService: ConfigAPIService {
        apiService
    }

    var deviceAPIService: DeviceAPIService {
        apiService
    }

    var fileAPIService: FileAPIService {
        apiService
    }

    var organizationAPIService: OrganizationAPIService {
        apiService
    }

    // MARK: Methods

    /// Gets the mediator to be used by an App Intent.
    public func getAppIntentMediator() -> AppIntentMediator {
        DefaultAppIntentMediator(
            authRepository: authRepository,
            configService: configService,
            errorReporter: errorReporter,
            generatorRepository: generatorRepository,
            stateService: stateService
        )
    }
}
