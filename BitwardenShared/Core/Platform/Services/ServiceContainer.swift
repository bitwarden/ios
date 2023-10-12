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

    /// The service used by the application to retrieve the current base url for API requests.
    let baseUrlService: BaseUrlService

    /// The service used by the application to generate captcha related artifacts.
    let captchaService: CaptchaService

    /// The client used by the application to handle auth related encryption and decryption tasks.
    let clientAuth: ClientAuthProtocol

    /// The service used by the application to manage account state.
    let stateService: StateService

    /// The object used by the application to retrieve information about this device.
    let systemDevice: SystemDevice

    /// The service used by the application to manage account access tokens.
    let tokenService: TokenService

    /// The repository used by the application to manage vault data for the UI layer.
    let vaultRepository: VaultRepository

    // MARK: Initialization

    /// Initialize a `ServiceContainer`.
    ///
    /// - Parameters:
    ///   - apiService: The service used by the application to make API requests.
    ///   - appSettingsStore: The service used by the application to persist app setting values.
    ///   - baseUrlService: The service used by the application to retrieve the current base url for API requests.
    ///   - captchaService: The service used by the application to create captcha related artifacts.
    ///   - clientAuth: The client used by the application to handle auth related encryption and decryption tasks.
    ///   - stateService: The service used by the application to manage account state.
    ///   - systemDevice: The object used by the application to retrieve information about this device.
    ///   - tokenService: The service used by the application to manage account access tokens.
    ///
    init(
        apiService: APIService,
        appSettingsStore: AppSettingsStore,
        baseUrlService: BaseUrlService,
        captchaService: CaptchaService,
        clientAuth: ClientAuthProtocol,
        stateService: StateService,
        systemDevice: SystemDevice,
        tokenService: TokenService
    ) {
        self.apiService = apiService
        self.appSettingsStore = appSettingsStore
        self.baseUrlService = baseUrlService
        self.captchaService = captchaService
        self.clientAuth = clientAuth
        self.stateService = stateService
        self.systemDevice = systemDevice
        self.tokenService = tokenService

        appIdService = AppIdService(appSettingStore: appSettingsStore)
        vaultRepository = DefaultVaultRepository(syncAPIService: apiService)
    }

    /// A convenience initializer to initialize the `ServiceContainer` with the default services.
    ///
    public convenience init() {
        let appSettingsStore = DefaultAppSettingsStore(
            userDefaults: UserDefaults(suiteName: Bundle.main.groupIdentifier)!
        )
        let baseUrlService = DefaultBaseUrlService(
            baseUrl: URL(string: "https://vault.bitwarden.com")!
        )

        let client = BitwardenSdk.Client(settings: nil)
        let stateService = DefaultStateService(appSettingsStore: appSettingsStore)
        let tokenService = DefaultTokenService(stateService: stateService)
        self.init(
            apiService: APIService(baseUrlService: baseUrlService, tokenService: tokenService),
            appSettingsStore: appSettingsStore,
            baseUrlService: baseUrlService,
            captchaService: DefaultCaptchaService(baseUrlService: baseUrlService),
            clientAuth: client.auth(),
            stateService: stateService,
            systemDevice: UIDevice.current,
            tokenService: tokenService
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
}
