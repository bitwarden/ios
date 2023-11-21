import BitwardenSdk
import Networking

@testable import BitwardenShared

extension ServiceContainer {
    static func withMocks(
        appSettingsStore: AppSettingsStore = MockAppSettingsStore(),
        authRepository: AuthRepository = MockAuthRepository(),
        baseUrlService: BaseUrlService = DefaultBaseUrlService(baseUrl: .example),
        biometricsService: BiometricsService = DefaultBiometricsService(),
        captchaService: CaptchaService = MockCaptchaService(),
        cameraAuthorizationService: CameraAuthorizationService = MockCameraAuthorizationService(),
        clientService: ClientService = MockClientService(),
        errorReporter: ErrorReporter = MockErrorReporter(),
        generatorRepository: GeneratorRepository = MockGeneratorRepository(),
        httpClient: HTTPClient = MockHTTPClient(),
        pasteboardService: PasteboardService = MockPasteboardService(),
        settingsRepository: SettingsRepository = MockSettingsRepository(),
        stateService: StateService = MockStateService(),
        systemDevice: SystemDevice = MockSystemDevice(),
        tokenService: TokenService = MockTokenService(),
        vaultRepository: VaultRepository = MockVaultRepository(),
        vaultTimeoutService: VaultTimeoutService = MockVaultTimeoutService()
    ) -> ServiceContainer {
        ServiceContainer(
            apiService: APIService(
                baseUrlService: baseUrlService,
                client: httpClient
            ),
            appSettingsStore: appSettingsStore,
            authRepository: authRepository,
            baseUrlService: baseUrlService,
            biometricsService: biometricsService,
            captchaService: captchaService,
            cameraAuthorizationService: cameraAuthorizationService,
            clientService: clientService,
            errorReporter: errorReporter,
            generatorRepository: generatorRepository,
            pasteboardService: pasteboardService,
            settingsRepository: settingsRepository,
            stateService: stateService,
            systemDevice: systemDevice,
            tokenService: tokenService,
            vaultRepository: vaultRepository,
            vaultTimeoutService: vaultTimeoutService
        )
    }
}
