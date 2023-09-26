import Networking

@testable import BitwardenShared

extension ServiceContainer {
    static func withMocks(
        appSettingsStore: AppSettingsStore = MockAppSettingsStore(),
        captchaService: CaptchaService = MockCaptchaService(),
        httpClient: HTTPClient = MockHTTPClient()
    ) -> ServiceContainer {
        ServiceContainer(
            apiService: APIService(
                baseUrl: .example,
                client: httpClient
            ),
            appSettingsStore: appSettingsStore,
            captchaService: captchaService
        )
    }
}
