/// The services provided by the `ServiceContainer`.
typealias Services = HasAccountAPIService
    & HasAPIService
    & HasAppIdService
    & HasAppSettingsStore
    & HasAuthAPIService
    & HasCaptchaService

/// Protocol for an object that provides an `AccountAPIService`.
///
protocol HasAccountAPIService {
    /// The services used by the application to make account related API requests.
    var accountAPIService: AccountAPIService { get }
}

/// Protocol for an object that provides an `APIService`.
///
protocol HasAPIService {
    /// The service used by the application to make API requests.
    var apiService: APIService { get }
}

/// Protocol for an object that provides an `AppIdService`.
///
protocol HasAppIdService {
    /// The service used by the application to manage the app's ID.
    var appIdService: AppIdService { get }
}

/// Protocol for an object that provides an `AppSettingsStore`.
///
protocol HasAppSettingsStore {
    /// The service used by the application to persist app setting values.
    var appSettingsStore: AppSettingsStore { get }
}

/// Protocol for an object that provides an `AuthAPIService`.
///
protocol HasAuthAPIService {
    /// The service used by the application to make auth-related API requests.
    var authAPIService: AuthAPIService { get }
}

/// Protocol for an object that provides a `BaseUrlService`.
///
protocol HasBaseUrlService {
    /// The service used by the application to retrieve the current base url for API requests.
    var baseUrlService: BaseUrlService { get }
}

/// Protocol for an object that provides a `CaptchaService`.
///
protocol HasCaptchaService {
    /// The service used by the application to generate captcha related artifacts.
    var captchaService: CaptchaService { get }
}
