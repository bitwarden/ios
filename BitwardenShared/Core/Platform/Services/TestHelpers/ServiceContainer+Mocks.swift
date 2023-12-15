import BitwardenSdk
import Networking

@testable import BitwardenShared

extension ServiceContainer {
    static func withMocks(
        appSettingsStore: AppSettingsStore = MockAppSettingsStore(),
        authRepository: AuthRepository = MockAuthRepository(),
        biometricsService: BiometricsService = DefaultBiometricsService(),
        captchaService: CaptchaService = MockCaptchaService(),
        cameraService: CameraService = MockCameraService(),
        clientService: ClientService = MockClientService(),
        environmentService: EnvironmentService = MockEnvironmentService(),
        errorReporter: ErrorReporter = MockErrorReporter(),
        generatorRepository: GeneratorRepository = MockGeneratorRepository(),
        httpClient: HTTPClient = MockHTTPClient(),
        pasteboardService: PasteboardService = MockPasteboardService(),
        settingsRepository: SettingsRepository = MockSettingsRepository(),
        stateService: StateService = MockStateService(),
        systemDevice: SystemDevice = MockSystemDevice(),
        tokenService: TokenService = MockTokenService(),
        totpService: TOTPService = MockTOTPService(),
        twoStepLoginService: TwoStepLoginService = MockTwoStepLoginService(),
        vaultRepository: VaultRepository = MockVaultRepository(),
        vaultTimeoutService: VaultTimeoutService = MockVaultTimeoutService()
    ) -> ServiceContainer {
        ServiceContainer(
            apiService: APIService(
                client: httpClient,
                environmentService: environmentService
            ),
            appSettingsStore: appSettingsStore,
            authRepository: authRepository,
            biometricsService: biometricsService,
            captchaService: captchaService,
            cameraService: cameraService,
            clientService: clientService,
            environmentService: environmentService,
            errorReporter: errorReporter,
            generatorRepository: generatorRepository,
            pasteboardService: pasteboardService,
            settingsRepository: settingsRepository,
            stateService: stateService,
            systemDevice: systemDevice,
            tokenService: tokenService,
            totpService: totpService,
            twoStepLoginService: twoStepLoginService,
            vaultRepository: vaultRepository,
            vaultTimeoutService: vaultTimeoutService
        )
    }
}
