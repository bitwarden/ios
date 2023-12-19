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

    /// The repository used by the application to manage data for the UI layer.
    let settingsRepository: SettingsRepository

    /// The service used by the application to manage account state.
    let stateService: StateService

    /// The service used to handle syncing vault data with the API.
    let syncService: SyncService

    /// The object used by the application to retrieve information about this device.
    let systemDevice: SystemDevice

    /// The service used by the application to manage account access tokens.
    let tokenService: TokenService

    /// The service used by the application to generate a two step login URL.
    let twoStepLoginService: TwoStepLoginService

    /// The repository used by the application to manage vault data for the UI layer.
    let vaultRepository: VaultRepository

    /// The service used by the application to manage vault access.
    let vaultTimeoutService: VaultTimeoutService

    // MARK: Initialization

    /// Initialize a `ServiceContainer`.
    ///
    /// - Parameters:
    ///   - apiService: The service used by the application to make API requests.
    ///   - appSettingsStore: The service used by the application to persist app setting values.
    ///   - authRepository: The repository used by the application to manage auth data for the UI layer.
    ///   - biometricsService: The service used to obtain the available authentication policies
    ///     and access controls for the user's device.
    ///   - captchaService: The service used by the application to create captcha related artifacts.
    ///   - cameraService: The service used by the application to manage camera use.
    ///   - clientService: The service used by the application to handle encryption and decryption tasks.
    ///   - environmentService: The service used by the application to manage the environment settings.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - generatorRepository: The repository used by the application to manage generator data for the UI layer.
    ///   - pasteboardService: The service used by the application for sharing data with other apps.
    ///   - settingsRepository: The repository used by the application to manage data for the UI layer.
    ///   - stateService: The service used by the application to manage account state.
    ///   - syncService: The service used to handle syncing vault data with the API.
    ///   - systemDevice: The object used by the application to retrieve information about this device.
    ///   - tokenService: The service used by the application to manage account access tokens.
    ///   - twoStepLoginService: The service used by the application to generate a two step login URL.
    ///   - vaultRepository: The repository used by the application to manage vault data for the UI layer.
    ///   - vaultTimeoutService: The service used by the application to manage vault access.
    ///
    init(
        apiService: APIService,
        appSettingsStore: AppSettingsStore,
        authRepository: AuthRepository,
        biometricsService: BiometricsService,
        captchaService: CaptchaService,
        cameraService: CameraService,
        clientService: ClientService,
        environmentService: EnvironmentService,
        errorReporter: ErrorReporter,
        generatorRepository: GeneratorRepository,
        pasteboardService: PasteboardService,
        settingsRepository: SettingsRepository,
        stateService: StateService,
        syncService: SyncService,
        systemDevice: SystemDevice,
        tokenService: TokenService,
        twoStepLoginService: TwoStepLoginService,
        vaultRepository: VaultRepository,
        vaultTimeoutService: VaultTimeoutService
    ) {
        self.apiService = apiService
        self.appSettingsStore = appSettingsStore
        self.authRepository = authRepository
        self.biometricsService = biometricsService
        self.captchaService = captchaService
        self.cameraService = cameraService
        self.clientService = clientService
        self.environmentService = environmentService
        self.errorReporter = errorReporter
        self.generatorRepository = generatorRepository
        self.pasteboardService = pasteboardService
        self.settingsRepository = settingsRepository
        self.stateService = stateService
        self.syncService = syncService
        self.systemDevice = systemDevice
        self.tokenService = tokenService
        self.twoStepLoginService = twoStepLoginService
        self.vaultRepository = vaultRepository
        self.vaultTimeoutService = vaultTimeoutService

        appIdService = AppIdService(appSettingStore: appSettingsStore)
    }

    /// A convenience initializer to initialize the `ServiceContainer` with the default services.
    ///
    /// - Parameter errorReporter: The service used by the application to report non-fatal errors.
    ///
    public convenience init(errorReporter: ErrorReporter) { // swiftlint:disable:this function_body_length
        let appSettingsStore = DefaultAppSettingsStore(
            userDefaults: UserDefaults(suiteName: Bundle.main.groupIdentifier)!
        )

        let biometricsService = DefaultBiometricsService()
        let clientService = DefaultClientService()
        let dataStore = DataStore(errorReporter: errorReporter)
        let stateService = DefaultStateService(appSettingsStore: appSettingsStore, dataStore: dataStore)
        let environmentService = DefaultEnvironmentService(stateService: stateService)
        let folderService = DefaultFolderService(folderDataStore: dataStore, stateService: stateService)
        let tokenService = DefaultTokenService(stateService: stateService)
        let apiService = APIService(environmentService: environmentService, tokenService: tokenService)
        let syncService = DefaultSyncService(
            clientCrypto: clientService.clientCrypto(),
            errorReporter: errorReporter,
            folderService: folderService,
            stateService: stateService,
            syncAPIService: apiService
        )
        let twoStepLoginService = DefaultTwoStepLoginService(environmentService: environmentService)
        let vaultTimeoutService = DefaultVaultTimeoutService(stateService: stateService)

        let authRepository = DefaultAuthRepository(
            accountAPIService: apiService,
            clientAuth: clientService.clientAuth(),
            clientCrypto: clientService.clientCrypto(),
            environmentService: environmentService,
            stateService: stateService,
            vaultTimeoutService: vaultTimeoutService
        )

        let generatorRepository = DefaultGeneratorRepository(
            clientGenerators: clientService.clientGenerator(),
            clientVaultService: clientService.clientVault(),
            dataStore: dataStore,
            stateService: stateService
        )

        let settingsRepository = DefaultSettingsRepository(
            stateService: stateService,
            vaultTimeoutService: vaultTimeoutService
        )

        let vaultRepository = DefaultVaultRepository(
            cipherAPIService: apiService,
            clientCrypto: clientService.clientCrypto(),
            clientVault: clientService.clientVault(),
            errorReporter: errorReporter,
            stateService: stateService,
            syncService: syncService,
            vaultTimeoutService: vaultTimeoutService
        )

        self.init(
            apiService: apiService,
            appSettingsStore: appSettingsStore,
            authRepository: authRepository,
            biometricsService: biometricsService,
            captchaService: DefaultCaptchaService(environmentService: environmentService),
            cameraService: DefaultCameraService(),
            clientService: clientService,
            environmentService: environmentService,
            errorReporter: errorReporter,
            generatorRepository: generatorRepository,
            pasteboardService: DefaultPasteboardService(),
            settingsRepository: settingsRepository,
            stateService: stateService,
            syncService: syncService,
            systemDevice: UIDevice.current,
            tokenService: tokenService,
            twoStepLoginService: twoStepLoginService,
            vaultRepository: vaultRepository,
            vaultTimeoutService: vaultTimeoutService
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
}
