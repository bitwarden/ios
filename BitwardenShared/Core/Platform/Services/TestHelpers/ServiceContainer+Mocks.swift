import BitwardenSdk
import Networking

@testable import BitwardenShared

extension ServiceContainer {
    static func withMocks(
        appSettingsStore: AppSettingsStore = MockAppSettingsStore(),
        authRepository: AuthRepository = MockAuthRepository(),
        baseUrlService: BaseUrlService = DefaultBaseUrlService(baseUrl: .example),
        captchaService: CaptchaService = MockCaptchaService(),
        clientService: ClientService = MockClientService(),
        generatorRepository: GeneratorRepository = MockGeneratorRepository(),
        httpClient: HTTPClient = MockHTTPClient(),
        settingsRepository: SettingsRepository = MockSettingsRepository(),
        stateService: StateService = MockStateService(),
        systemDevice: SystemDevice = MockSystemDevice(),
        tokenService: TokenService = MockTokenService(),
        vaultRepository: VaultRepository = MockVaultRepository()
    ) -> ServiceContainer {
        ServiceContainer(
            apiService: APIService(
                baseUrlService: baseUrlService,
                client: httpClient
            ),
            appSettingsStore: appSettingsStore,
            authRepository: authRepository,
            baseUrlService: baseUrlService,
            captchaService: captchaService,
            clientService: clientService,
            generatorRepository: generatorRepository,
            settingsRepository: settingsRepository,
            stateService: stateService,
            systemDevice: systemDevice,
            tokenService: tokenService,
            vaultRepository: vaultRepository
        )
    }
}
