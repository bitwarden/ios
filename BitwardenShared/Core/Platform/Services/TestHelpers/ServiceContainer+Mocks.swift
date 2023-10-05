import BitwardenSdk
import Networking

@testable import BitwardenShared

extension ServiceContainer {
    static func withMocks(
        appSettingsStore: AppSettingsStore = MockAppSettingsStore(),
        baseUrlService: BaseUrlService = DefaultBaseUrlService(baseUrl: .example),
        captchaService: CaptchaService = MockCaptchaService(),
        clientAuth: ClientAuthProtocol = MockClientAuth(),
        systemDevice: SystemDevice = MockSystemDevice(),
        httpClient: HTTPClient = MockHTTPClient()
    ) -> ServiceContainer {
        ServiceContainer(
            apiService: APIService(
                baseUrlService: baseUrlService,
                client: httpClient
            ),
            appSettingsStore: appSettingsStore,
            baseUrlService: baseUrlService,
            captchaService: captchaService,
            clientAuth: clientAuth,
            systemDevice: systemDevice
        )
    }
}
