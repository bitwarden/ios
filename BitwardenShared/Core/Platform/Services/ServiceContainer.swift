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

    /// The service used by the application to make API requests.
    let apiService: APIService

    /// The service used by the application to manage the app's ID.
    let appIdService: AppIdService

    /// The service used by the application to persist app setting values.
    let appSettingsStore: AppSettingsStore

    /// The repository used by the application to manage auth data for the UI layer.
    let authRepository: AuthRepository

    /// The service used by the application to handle authentication tasks.
    let authService: AuthService

    /// The service used to obtain the available authentication policies and access controls for the user's device.
    let biometricsService: BiometricsService

    /// The service used by the application to generate captcha related artifacts.
    let captchaService: CaptchaService

    /// The service used by the application to manage camera use.
    let cameraService: CameraService

    /// The service used by the application to handle encryption and decryption tasks.
    let clientService: ClientService

    /// The service used by the application to manage the environment settings.
    let environmentService: EnvironmentService

    /// The service used by the application to report non-fatal errors.
    let errorReporter: ErrorReporter

    /// The repository used by the application to manage generator data for the UI layer.
    let generatorRepository: GeneratorRepository

    /// The service used by the application for sharing data with other apps.
    let pasteboardService: PasteboardService

    /// The repository used by the application to manage send data for the UI layer.
    let sendRepository: SendRepository

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
    ///   - appSettingsStore: The service used by the application to persist app setting values.
    ///   - authRepository: The repository used by the application to manage auth data for the UI layer.
    ///   - authService: The service used by the application to handle authentication tasks.
    ///   - biometricsService: The service used to obtain the available authentication policies
    ///     and access controls for the user's device.
    ///   - captchaService: The service used by the application to create captcha related artifacts.
    ///   - cameraService: The service used by the application to manage camera use.
    ///   - clientService: The service used by the application to handle encryption and decryption tasks.
    ///   - environmentService: The service used by the application to manage the environment settings.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - generatorRepository: The repository used by the application to manage generator data for the UI layer.
    ///   - pasteboardService: The service used by the application for sharing data with other apps.
    ///   - sendRepository: The repository used by the application to manage send data for the UI layer.
    ///   - settingsRepository: The repository used by the application to manage data for the UI layer.
    ///   - stateService: The service used by the application to manage account state.
    ///   - syncService: The service used to handle syncing vault data with the API.
    ///   - systemDevice: The object used by the application to retrieve information about this device.
    ///   - timeProvider: Provides the present time for TOTP Code Calculation.
    ///   - tokenService: The service used by the application to manage account access tokens.
    ///   - totpService: The service used by the application to validate TOTP keys and produce TOTP values.
    ///   - twoStepLoginService: The service used by the application to generate a two step login URL.
    ///   - vaultRepository: The repository used by the application to manage vault data for the UI layer.
    ///   - vaultTimeoutService: The service used by the application to manage vault access.
    ///   - watchService: The service used by the application to connect to and communicate with the watch app.
    ///
    init(
        apiService: APIService,
        appIdService: AppIdService,
        appSettingsStore: AppSettingsStore,
        authRepository: AuthRepository,
        authService: AuthService,
        biometricsService: BiometricsService,
        captchaService: CaptchaService,
        cameraService: CameraService,
        clientService: ClientService,
        environmentService: EnvironmentService,
        errorReporter: ErrorReporter,
        generatorRepository: GeneratorRepository,
        pasteboardService: PasteboardService,
        sendRepository: SendRepository,
        settingsRepository: SettingsRepository,
        stateService: StateService,
        syncService: SyncService,
        systemDevice: SystemDevice,
        timeProvider: TimeProvider,
        tokenService: TokenService,
        totpService: TOTPService,
        twoStepLoginService: TwoStepLoginService,
        vaultRepository: VaultRepository,
        vaultTimeoutService: VaultTimeoutService,
        watchService: WatchService
    ) {
        self.apiService = apiService
        self.appIdService = appIdService
        self.appSettingsStore = appSettingsStore
        self.authRepository = authRepository
        self.authService = authService
        self.biometricsService = biometricsService
        self.captchaService = captchaService
        self.cameraService = cameraService
        self.clientService = clientService
        self.environmentService = environmentService
        self.errorReporter = errorReporter
        self.generatorRepository = generatorRepository
        self.pasteboardService = pasteboardService
        self.sendRepository = sendRepository
        self.settingsRepository = settingsRepository
        self.stateService = stateService
        self.syncService = syncService
        self.systemDevice = systemDevice
        self.timeProvider = timeProvider
        self.tokenService = tokenService
        self.totpService = totpService
        self.twoStepLoginService = twoStepLoginService
        self.vaultRepository = vaultRepository
        self.vaultTimeoutService = vaultTimeoutService
        self.watchService = watchService
    }

    /// A convenience initializer to initialize the `ServiceContainer` with the default services.
    ///
    /// - Parameter errorReporter: The service used by the application to report non-fatal errors.
    ///
    public convenience init(errorReporter: ErrorReporter) { // swiftlint:disable:this function_body_length
        let appSettingsStore = DefaultAppSettingsStore(
            userDefaults: UserDefaults(suiteName: Bundle.main.groupIdentifier)!
        )
        let appIdService = AppIdService(appSettingStore: appSettingsStore)

        let dataStore = DataStore(errorReporter: errorReporter)
        let stateService = DefaultStateService(appSettingsStore: appSettingsStore, dataStore: dataStore)

        let biometricsService = DefaultBiometricsService(stateService: stateService)
        let clientService = DefaultClientService()
        let environmentService = DefaultEnvironmentService(stateService: stateService)
        let collectionService = DefaultCollectionService(collectionDataStore: dataStore, stateService: stateService)
        let settingsService = DefaultSettingsService(settingsDataStore: dataStore, stateService: stateService)
        let tokenService = DefaultTokenService(stateService: stateService)
        let apiService = APIService(environmentService: environmentService, tokenService: tokenService)
        let captchaService = DefaultCaptchaService(environmentService: environmentService, stateService: stateService)

        let cipherService = DefaultCipherService(
            cipherAPIService: apiService,
            cipherDataStore: dataStore,
            stateService: stateService
        )

        let folderService = DefaultFolderService(
            folderAPIService: apiService,
            folderDataStore: dataStore,
            stateService: stateService
        )

        let organizationService = DefaultOrganizationService(
            clientCrypto: clientService.clientCrypto(),
            errorReporter: errorReporter,
            organizationDataStore: dataStore,
            stateService: stateService
        )

        let sendService = DefaultSendService(
            sendAPIService: apiService,
            sendDataStore: dataStore,
            stateService: stateService
        )

        let watchService = DefaultWatchService(
            cipherService: cipherService,
            clientVault: clientService.clientVault(),
            environmentService: environmentService,
            errorReporter: errorReporter,
            organizationService: organizationService,
            stateService: stateService
        )

        let syncService = DefaultSyncService(
            cipherService: cipherService,
            collectionService: collectionService,
            folderService: folderService,
            organizationService: organizationService,
            sendService: sendService,
            settingsService: settingsService,
            stateService: stateService,
            syncAPIService: apiService
        )

        let totpService = DefaultTOTPService()

        let twoStepLoginService = DefaultTwoStepLoginService(environmentService: environmentService)

        let vaultTimeoutService = DefaultVaultTimeoutService(stateService: stateService)

        let pasteboardService = DefaultPasteboardService(
            errorReporter: errorReporter,
            stateService: stateService
        )

        let authService = DefaultAuthService(
            accountAPIService: apiService,
            appIdService: appIdService,
            authAPIService: apiService,
            clientAuth: clientService.clientAuth(),
            clientGenerators: clientService.clientGenerator(),
            environmentService: environmentService,
            stateService: stateService,
            systemDevice: UIDevice.current
        )

        let authRepository = DefaultAuthRepository(
            accountAPIService: apiService,
            authService: authService,
            biometricsService: biometricsService,
            clientAuth: clientService.clientAuth(),
            clientCrypto: clientService.clientCrypto(),
            clientPlatform: clientService.clientPlatform(),
            environmentService: environmentService,
            organizationService: organizationService,
            stateService: stateService,
            vaultTimeoutService: vaultTimeoutService
        )

        let generatorRepository = DefaultGeneratorRepository(
            clientGenerators: clientService.clientGenerator(),
            clientVaultService: clientService.clientVault(),
            dataStore: dataStore,
            stateService: stateService
        )

        let sendRepository = DefaultSendRepository(
            clientVault: clientService.clientVault(),
            organizationService: organizationService,
            sendService: sendService,
            stateService: stateService,
            syncService: syncService
        )

        let settingsRepository = DefaultSettingsRepository(
            clientAuth: clientService.clientAuth(),
            clientVault: clientService.clientVault(),
            folderService: folderService,
            pasteboardService: pasteboardService,
            stateService: stateService,
            syncService: syncService,
            vaultTimeoutService: vaultTimeoutService
        )

        let timeProvider = CurrentTime()

        let vaultRepository = DefaultVaultRepository(
            cipherAPIService: apiService,
            cipherService: cipherService,
            clientAuth: clientService.clientAuth(),
            clientCrypto: clientService.clientCrypto(),
            clientVault: clientService.clientVault(),
            collectionService: collectionService,
            environmentService: environmentService,
            errorReporter: errorReporter,
            folderService: folderService,
            organizationService: organizationService,
            stateService: stateService,
            syncService: syncService,
            vaultTimeoutService: vaultTimeoutService
        )

        self.init(
            apiService: apiService,
            appIdService: appIdService,
            appSettingsStore: appSettingsStore,
            authRepository: authRepository,
            authService: authService,
            biometricsService: biometricsService,
            captchaService: captchaService,
            cameraService: DefaultCameraService(),
            clientService: clientService,
            environmentService: environmentService,
            errorReporter: errorReporter,
            generatorRepository: generatorRepository,
            pasteboardService: pasteboardService,
            sendRepository: sendRepository,
            settingsRepository: settingsRepository,
            stateService: stateService,
            syncService: syncService,
            systemDevice: UIDevice.current,
            timeProvider: timeProvider,
            tokenService: tokenService,
            totpService: totpService,
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

    var deviceAPIService: DeviceAPIService {
        apiService
    }

    var clientAuth: ClientAuthProtocol {
        clientService.clientAuth()
    }

    var clientCrypto: ClientCryptoProtocol {
        clientService.clientCrypto()
    }

    var clientPlatform: ClientPlatformProtocol {
        clientService.clientPlatform()
    }
}
