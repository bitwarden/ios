import BitwardenSdk
import Networking

@testable import BitwardenShared

extension ServiceContainer {
    static func withMocks(
        appSettingsStore: AppSettingsStore = MockAppSettingsStore(),
        baseUrlService: BaseUrlService = DefaultBaseUrlService(baseUrl: .example),
        captchaService: CaptchaService = MockCaptchaService(),
        clientService: ClientService = MockClientService(),
        systemDevice: SystemDevice = MockSystemDevice(),
        generatorRepository: GeneratorRepository = MockGeneratorRepository(),
        httpClient: HTTPClient = MockHTTPClient(),
        stateService: StateService = MockStateService(),
        tokenService: TokenService = MockTokenService()
    ) -> ServiceContainer {
        ServiceContainer(
            apiService: APIService(
                baseUrlService: baseUrlService,
                client: httpClient
            ),
            appSettingsStore: appSettingsStore,
            baseUrlService: baseUrlService,
            captchaService: captchaService,
            clientService: clientService,
            generatorRepository: generatorRepository,
            stateService: stateService,
            systemDevice: systemDevice,
            tokenService: tokenService
        )
    }
}
