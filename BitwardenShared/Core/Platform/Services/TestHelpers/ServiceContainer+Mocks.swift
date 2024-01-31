import BitwardenSdk
import Networking

@testable import BitwardenShared

extension ServiceContainer {
    static func withMocks(
        appSettingsStore: AppSettingsStore = MockAppSettingsStore(),
        authRepository: AuthRepository = MockAuthRepository(),
        authService: AuthService = MockAuthService(),
        biometricsRepository: BiometricsRepository = MockBiometricsRepository(),
        biometricsService: BiometricsService = MockBiometricsService(),
        captchaService: CaptchaService = MockCaptchaService(),
        cameraService: CameraService = MockCameraService(),
        clientService: ClientService = MockClientService(),
        environmentService: EnvironmentService = MockEnvironmentService(),
        errorReporter: ErrorReporter = MockErrorReporter(),
        generatorRepository: GeneratorRepository = MockGeneratorRepository(),
        httpClient: HTTPClient = MockHTTPClient(),
        keychainService: KeychainRepository = MockKeychainService(),
        notificationService: NotificationService = MockNotificationService(),
        pasteboardService: PasteboardService = MockPasteboardService(),
        policyService: PolicyService = MockPolicyService(),
        notificationCenterService: NotificationCenterService = MockNotificationCenterService(),
        sendRepository: SendRepository = MockSendRepository(),
        settingsRepository: SettingsRepository = MockSettingsRepository(),
        stateService: StateService = MockStateService(),
        syncService: SyncService = MockSyncService(),
        systemDevice: SystemDevice = MockSystemDevice(),
        timeProvider: TimeProvider = MockTimeProvider(.currentTime),
        tokenService: TokenService = MockTokenService(),
        totpService: TOTPService = MockTOTPService(),
        twoStepLoginService: TwoStepLoginService = MockTwoStepLoginService(),
        vaultRepository: VaultRepository = MockVaultRepository(),
        vaultTimeoutService: VaultTimeoutService = MockVaultTimeoutService(),
        watchService: WatchService = MockWatchService()
    ) -> ServiceContainer {
        ServiceContainer(
            apiService: APIService(
                client: httpClient,
                environmentService: environmentService
            ),
            appIdService: AppIdService(appSettingStore: appSettingsStore),
            appSettingsStore: appSettingsStore,
            authRepository: authRepository,
            authService: authService,
            biometricsRepository: biometricsRepository,
            biometricsService: biometricsService,
            captchaService: captchaService,
            cameraService: cameraService,
            clientService: clientService,
            environmentService: environmentService,
            errorReporter: errorReporter,
            generatorRepository: generatorRepository,
            keychainService: keychainService,
            notificationCenterService: notificationCenterService,
            notificationService: notificationService,
            pasteboardService: pasteboardService,
            policyService: policyService,
            sendRepository: sendRepository,
            settingsRepository: settingsRepository,
            stateService: stateService,
            syncService: syncService,
            systemDevice: systemDevice,
            timeProvider: timeProvider,
            tokenService: tokenService,
            totpService: totpService,
            twoStepLoginService: twoStepLoginService,
            vaultRepository: vaultRepository,
            vaultTimeoutService: vaultTimeoutService,
            watchService: watchService
        )
    }
}
