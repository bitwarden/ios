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
    // MARK: Properties

    /// The service used by the application to make API requests.
    let apiService: APIService

    /// The service used by the application to manage the app's ID.
    let appIdService: AppIdService

    /// The application instance (i.e. `UIApplication`), if the app isn't running in an extension.
    let application: Application?

    /// The service used by the application to persist app setting values.
    let appSettingsStore: AppSettingsStore

    /// The repository used by the application to manage auth data for the UI layer.
    let authRepository: AuthRepository

    /// The service used by the application to handle authentication tasks.
    let authService: AuthService

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

    /// The service used by the application to report non-fatal errors.
    let errorReporter: ErrorReporter

    /// The service used to record and send events.
    let eventService: EventService

    /// The service used to export a vault.
    let exportVaultService: ExportVaultService

    /// A store to be used on Fido2 flows to get/save credentials.
    let fido2CredentialStore: Fido2CredentialStore

    /// A helper to be used on Fido2 flows that requires user interaction and extends the capabilities
    /// of the `Fido2UserInterface` from the SDK.
    let fido2UserInterfaceHelper: Fido2UserInterfaceHelper

    /// The repository used by the application to manage generator data for the UI layer.
    let generatorRepository: GeneratorRepository

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

    /// The service for managing the polices for the user.
    let policyService: PolicyService

    /// The repository used by the application to manage send data for the UI layer.
    public let sendRepository: SendRepository

    /// The repository used by the application to manage data for the UI layer.
    let settingsRepository: SettingsRepository

    /// The service used by the application to manage account state.
    let stateService: StateService

    /// The service used to handle syncing vault data with the API.
    let syncService: SyncService

    /// The object used by the application to retrieve information about this device.
    let systemDevice: SystemDevice

    /// Provides the present time for TOTP Code Calculation.
    let timeProvider: TimeProvider

    /// The service used by the application to manage account access tokens.
    let tokenService: TokenService

    /// The service used by the application to validate TOTP keys and produce TOTP values.
    let totpService: TOTPService

    /// A service used to handle device trust.
    let trustDeviceService: TrustDeviceService

    /// The service used by the application to generate a two step login URL.
    let twoStepLoginService: TwoStepLoginService

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
    ///   - appIdService: The service used by the application to manage the app's ID.
    ///   - application: The application instance.
    ///   - appSettingsStore: The service used by the application to persist app setting values.
    ///   - authRepository: The repository used by the application to manage auth data for the UI layer.
    ///   - authService: The service used by the application to handle authentication tasks.
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
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - eventService: The service used to record and send events.
    ///   - exportVaultService: The service used to export vaults.
    ///   - fido2UserInterfaceHelper: A helper to be used on Fido2 flows that requires user interaction
    ///   and extends the capabilities of the `Fido2UserInterface` from the SDK.
    ///   - fido2CredentialStore: A store to be used on Fido2 flows to get/save credentials.
    ///   - generatorRepository: The repository used by the application to manage generator data for the UI layer.
    ///   - keychainRepository: The repository used to manages keychain items.
    ///   - keychainService: The service used to access & store data on the device keychain.
    ///   - localAuthService: The service used by the application to evaluate local auth policies.
    ///   - migrationService: The serviced used to perform app data migrations.
    ///   - nfcReaderService: The service used by the application to read NFC tags.
    ///   - notificationCenterService: The service used by the application to access the system's notification center.
    ///   - notificationService: The service used by the application to handle notifications.
    ///   - pasteboardService: The service used by the application for sharing data with other apps.
    ///   - policyService: The service for managing the polices for the user.
    ///   - sendRepository: The repository used by the application to manage send data for the UI layer.
    ///   - settingsRepository: The repository used by the application to manage data for the UI layer.
    ///   - stateService: The service used by the application to manage account state.
    ///   - syncService: The service used to handle syncing vault data with the API.
    ///   - systemDevice: The object used by the application to retrieve information about this device.
    ///   - timeProvider: Provides the present time for TOTP Code Calculation.
    ///   - tokenService: The service used by the application to manage account access tokens.
    ///   - totpService: The service used by the application to validate TOTP keys and produce TOTP values.
    ///   - trustDeviceService: The service used to handle device trust.
    ///   - twoStepLoginService: The service used by the application to generate a two step login URL.
    ///   - vaultRepository: The repository used by the application to manage vault data for the UI layer.
    ///   - vaultTimeoutService: The service used by the application to manage vault access.
    ///   - watchService: The service used by the application to connect to and communicate with the watch app.
    ///
    init(
        apiService: APIService,
        appIdService: AppIdService,
        application: Application?,
        appSettingsStore: AppSettingsStore,
        authRepository: AuthRepository,
        authService: AuthService,
        autofillCredentialService: AutofillCredentialService,
        biometricsRepository: BiometricsRepository,
        biometricsService: BiometricsService,
        captchaService: CaptchaService,
        cameraService: CameraService,
        clientService: ClientService,
        configService: ConfigService,
        environmentService: EnvironmentService,
        errorReporter: ErrorReporter,
        eventService: EventService,
        exportVaultService: ExportVaultService,
        fido2CredentialStore: Fido2CredentialStore,
        fido2UserInterfaceHelper: Fido2UserInterfaceHelper,
        generatorRepository: GeneratorRepository,
        keychainRepository: KeychainRepository,
        keychainService: KeychainService,
        localAuthService: LocalAuthService,
        migrationService: MigrationService,
        nfcReaderService: NFCReaderService,
        notificationCenterService: NotificationCenterService,
        notificationService: NotificationService,
        pasteboardService: PasteboardService,
        policyService: PolicyService,
        sendRepository: SendRepository,
        settingsRepository: SettingsRepository,
        stateService: StateService,
        syncService: SyncService,
        systemDevice: SystemDevice,
        timeProvider: TimeProvider,
        tokenService: TokenService,
        totpService: TOTPService,
        trustDeviceService: TrustDeviceService,
        twoStepLoginService: TwoStepLoginService,
        vaultRepository: VaultRepository,
        vaultTimeoutService: VaultTimeoutService,
        watchService: WatchService
    ) {
        self.apiService = apiService
        self.appIdService = appIdService
        self.application = application
        self.appSettingsStore = appSettingsStore
        self.authRepository = authRepository
        self.authService = authService
        self.autofillCredentialService = autofillCredentialService
        self.biometricsRepository = biometricsRepository
        self.biometricsService = biometricsService
        self.captchaService = captchaService
        self.cameraService = cameraService
        self.clientService = clientService
        self.configService = configService
        self.environmentService = environmentService
        self.errorReporter = errorReporter
        self.eventService = eventService
        self.exportVaultService = exportVaultService
        self.fido2CredentialStore = fido2CredentialStore
        self.fido2UserInterfaceHelper = fido2UserInterfaceHelper
        self.generatorRepository = generatorRepository
        self.keychainService = keychainService
        self.keychainRepository = keychainRepository
        self.localAuthService = localAuthService
        self.migrationService = migrationService
        self.nfcReaderService = nfcReaderService
        self.notificationCenterService = notificationCenterService
        self.notificationService = notificationService
        self.pasteboardService = pasteboardService
        self.policyService = policyService
        self.sendRepository = sendRepository
        self.settingsRepository = settingsRepository
        self.stateService = stateService
        self.syncService = syncService
        self.systemDevice = systemDevice
        self.timeProvider = timeProvider
        self.tokenService = tokenService
        self.totpService = totpService
        self.trustDeviceService = trustDeviceService
        self.twoStepLoginService = twoStepLoginService
        self.vaultRepository = vaultRepository
        self.vaultTimeoutService = vaultTimeoutService
        self.watchService = watchService
    }

    /// A convenience initializer to initialize the `ServiceContainer` with the default services.
    ///
    /// - Parameters:
    ///   - application: The application instance.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - nfcReaderService: The service used by the application to read NFC tags.
    ///
    public convenience init( // swiftlint:disable:this function_body_length
        application: Application? = nil,
        errorReporter: ErrorReporter,
        nfcReaderService: NFCReaderService? = nil
    ) {
        let appSettingsStore = DefaultAppSettingsStore(
            userDefaults: UserDefaults(suiteName: Bundle.main.groupIdentifier)!
        )
        let appIdService = AppIdService(appSettingStore: appSettingsStore)

        let dataStore = DataStore(errorReporter: errorReporter)

        let keychainService = DefaultKeychainService()

        let keychainRepository = DefaultKeychainRepository(
            appIdService: appIdService,
            keychainService: keychainService
        )
        let timeProvider = CurrentTime()

        let stateService = DefaultStateService(
            appSettingsStore: appSettingsStore,
            dataStore: dataStore,
            keychainRepository: keychainRepository
        )

        let clientBuilder = DefaultClientBuilder(errorReporter: errorReporter)
        let clientService = DefaultClientService(
            clientBuilder: clientBuilder,
            errorReporter: errorReporter,
            stateService: stateService
        )

        let biometricsService = DefaultBiometricsService()
        let biometricsRepository = DefaultBiometricsRepository(
            biometricsService: biometricsService,
            keychainService: keychainRepository,
            stateService: stateService
        )

        let localAuthService = DefaultLocalAuthService()

        let environmentService = DefaultEnvironmentService(stateService: stateService)
        let collectionService = DefaultCollectionService(collectionDataStore: dataStore, stateService: stateService)
        let settingsService = DefaultSettingsService(settingsDataStore: dataStore, stateService: stateService)
        let tokenService = DefaultTokenService(keychainRepository: keychainRepository, stateService: stateService)
        let apiService = APIService(environmentService: environmentService, tokenService: tokenService)
        let captchaService = DefaultCaptchaService(environmentService: environmentService, stateService: stateService)
        let notificationCenterService = DefaultNotificationCenterService()

        let configService = DefaultConfigService(
            configApiService: apiService,
            errorReporter: errorReporter,
            stateService: stateService,
            timeProvider: timeProvider
        )

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
            organizationService: organizationService,
            policyDataStore: dataStore,
            stateService: stateService
        )

        let cipherService = DefaultCipherService(
            cipherAPIService: apiService,
            cipherDataStore: dataStore,
            fileAPIService: apiService,
            stateService: stateService
        )

        let eventService = DefaultEventService(
            cipherService: cipherService,
            errorReporter: errorReporter,
            organizationService: organizationService,
            stateService: stateService,
            timeProvider: timeProvider
        )

        let exportVaultService = DefultExportVaultService(
            cipherService: cipherService,
            clientService: clientService,
            errorReporter: errorReporter,
            folderService: folderService,
            stateService: stateService,
            timeProvider: timeProvider
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

        let syncService = DefaultSyncService(
            accountAPIService: apiService,
            cipherService: cipherService,
            clientService: clientService,
            collectionService: collectionService,
            folderService: folderService,
            organizationService: organizationService,
            policyService: policyService,
            sendService: sendService,
            settingsService: settingsService,
            stateService: stateService,
            syncAPIService: apiService,
            timeProvider: timeProvider
        )

        let totpService = DefaultTOTPService()

        let trustDeviceService = DefaultTrustDeviceService(
            appIdService: appIdService,
            authAPIService: apiService,
            clientService: clientService,
            keychainRepository: keychainRepository,
            stateService: stateService
        )

        let twoStepLoginService = DefaultTwoStepLoginService(environmentService: environmentService)
        let vaultTimeoutService = DefaultVaultTimeoutService(
            clientService: clientService,
            stateService: stateService,
            timeProvider: timeProvider
        )

        let pasteboardService = DefaultPasteboardService(
            errorReporter: errorReporter,
            stateService: stateService
        )

        let authService = DefaultAuthService(
            accountAPIService: apiService,
            appIdService: appIdService,
            authAPIService: apiService,
            clientService: clientService,
            environmentService: environmentService,
            keychainRepository: keychainRepository,
            policyService: policyService,
            stateService: stateService,
            systemDevice: UIDevice.current,
            trustDeviceService: trustDeviceService
        )

        let authRepository = DefaultAuthRepository(
            accountAPIService: apiService,
            authService: authService,
            biometricsRepository: biometricsRepository,
            clientService: clientService,
            configService: configService,
            environmentService: environmentService,
            keychainService: keychainRepository,
            organizationAPIService: apiService,
            organizationService: organizationService,
            organizationUserAPIService: apiService,
            stateService: stateService,
            trustDeviceService: trustDeviceService,
            vaultTimeoutService: vaultTimeoutService
        )

        let migrationService = DefaultMigrationService(
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

        let vaultRepository = DefaultVaultRepository(
            cipherService: cipherService,
            clientService: clientService,
            collectionService: collectionService,
            configService: configService,
            environmentService: environmentService,
            errorReporter: errorReporter,
            folderService: folderService,
            organizationService: organizationService,
            settingsService: settingsService,
            stateService: stateService,
            syncService: syncService,
            timeProvider: timeProvider,
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

        let autofillCredentialService = DefaultAutofillCredentialService(
            cipherService: cipherService,
            clientService: clientService,
            errorReporter: errorReporter,
            eventService: eventService,
            fido2CredentialStore: fido2CredentialStore,
            fido2UserInterfaceHelper: fido2UserInterfaceHelper,
            pasteboardService: pasteboardService,
            stateService: stateService,
            vaultTimeoutService: vaultTimeoutService
        )

        self.init(
            apiService: apiService,
            appIdService: appIdService,
            application: application,
            appSettingsStore: appSettingsStore,
            authRepository: authRepository,
            authService: authService,
            autofillCredentialService: autofillCredentialService,
            biometricsRepository: biometricsRepository,
            biometricsService: biometricsService,
            captchaService: captchaService,
            cameraService: DefaultCameraService(),
            clientService: clientService,
            configService: configService,
            environmentService: environmentService,
            errorReporter: errorReporter,
            eventService: eventService,
            exportVaultService: exportVaultService,
            fido2CredentialStore: fido2CredentialStore,
            fido2UserInterfaceHelper: fido2UserInterfaceHelper,
            generatorRepository: generatorRepository,
            keychainRepository: keychainRepository,
            keychainService: keychainService,
            localAuthService: localAuthService,
            migrationService: migrationService,
            nfcReaderService: nfcReaderService ?? NoopNFCReaderService(),
            notificationCenterService: notificationCenterService,
            notificationService: notificationService,
            pasteboardService: pasteboardService,
            policyService: policyService,
            sendRepository: sendRepository,
            settingsRepository: settingsRepository,
            stateService: stateService,
            syncService: syncService,
            systemDevice: UIDevice.current,
            timeProvider: timeProvider,
            tokenService: tokenService,
            totpService: totpService,
            trustDeviceService: trustDeviceService,
            twoStepLoginService: twoStepLoginService,
            vaultRepository: vaultRepository,
            vaultTimeoutService: vaultTimeoutService,
            watchService: watchService
        )
    }
}

extension ServiceContainer {
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
}
