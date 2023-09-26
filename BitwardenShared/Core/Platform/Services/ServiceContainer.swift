import Foundation

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

    let captchaService: CaptchaService

    // MARK: Initialization

    /// Initialize a `ServiceContainer`.
    ///
    /// - Parameters:
    ///   - apiService: The service used by the application to make API requests.
    ///   - appSettingsStore: The service used by the application to persist app setting values.
    ///
    init(
        apiService: APIService,
        appSettingsStore: AppSettingsStore,
        captchaService: CaptchaService
    ) {
        self.apiService = apiService
        self.appSettingsStore = appSettingsStore
        self.captchaService = captchaService

        appIdService = AppIdService(appSettingStore: appSettingsStore)
    }

    /// A convenience initializer to initialize the `ServiceContainer` with the default services.
    ///
    public convenience init() {
        let baseUrl = URL(string: "https://vault.bitwarden.com")!
        let callbackUrlScheme = "bitwarden"
        self.init(
            apiService: APIService(baseUrl: baseUrl),
            appSettingsStore: DefaultAppSettingsStore(userDefaults: UserDefaults.standard),
            captchaService: DefaultCaptchaService(baseUrl: baseUrl, callbackUrlScheme: callbackUrlScheme)
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
}
