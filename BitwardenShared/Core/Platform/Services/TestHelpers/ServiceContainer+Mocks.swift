import BitwardenSdk
import Networking

@testable import BitwardenShared

extension ServiceContainer {
    static func withMocks( // swiftlint:disable:this function_body_length
        application: Application? = nil,
        appSettingsStore: AppSettingsStore = MockAppSettingsStore(),
        authRepository: AuthRepository = MockAuthRepository(),
        authService: AuthService = MockAuthService(),
        authenticatorSyncService: AuthenticatorSyncService = MockAuthenticatorSyncService(),
        autofillCredentialService: AutofillCredentialService = MockAutofillCredentialService(),
        biometricsRepository: BiometricsRepository = MockBiometricsRepository(),
        biometricsService: BiometricsService = MockBiometricsService(),
        captchaService: CaptchaService = MockCaptchaService(),
        cameraService: CameraService = MockCameraService(),
        clientService: ClientService = MockClientService(),
        configService: ConfigService = MockConfigService(),
        environmentService: EnvironmentService = MockEnvironmentService(),
        errorReporter: ErrorReporter = MockErrorReporter(),
        eventService: EventService = MockEventService(),
        exportVaultService: ExportVaultService = MockExportVaultService(),
        fido2CredentialStore: Fido2CredentialStore = MockFido2CredentialStore(),
        fido2UserInterfaceHelper: Fido2UserInterfaceHelper = MockFido2UserInterfaceHelper(),
        generatorRepository: GeneratorRepository = MockGeneratorRepository(),
        importCiphersRepository: ImportCiphersRepository = MockImportCiphersRepository(),
        httpClient: HTTPClient = MockHTTPClient(),
        keychainRepository: KeychainRepository = MockKeychainRepository(),
        keychainService: KeychainService = MockKeychainService(),
        localAuthService: LocalAuthService = MockLocalAuthService(),
        migrationService: MigrationService = MockMigrationService(),
        nfcReaderService: NFCReaderService = MockNFCReaderService(),
        notificationService: NotificationService = MockNotificationService(),
        pasteboardService: PasteboardService = MockPasteboardService(),
        policyService: PolicyService = MockPolicyService(),
        notificationCenterService: NotificationCenterService = MockNotificationCenterService(),
        rehydrationHelper: RehydrationHelper = MockRehydrationHelper(),
        reviewPromptService: ReviewPromptService = MockReviewPromptService(),
        sendRepository: SendRepository = MockSendRepository(),
        settingsRepository: SettingsRepository = MockSettingsRepository(),
        stateService: StateService = MockStateService(),
        syncService: SyncService = MockSyncService(),
        systemDevice: SystemDevice = MockSystemDevice(),
        textAutofillHelperFactory: TextAutofillHelperFactory = MockTextAutofillHelperFactory(),
        timeProvider: TimeProvider = MockTimeProvider(.currentTime),
        trustDeviceService: TrustDeviceService = MockTrustDeviceService(),
        tokenService: TokenService = MockTokenService(),
        totpExpirationManagerFactory: TOTPExpirationManagerFactory = MockTOTPExpirationManagerFactory(),
        totpService: TOTPService = MockTOTPService(),
        twoStepLoginService: TwoStepLoginService = MockTwoStepLoginService(),
        userVerificationHelperFactory: UserVerificationHelperFactory = MockUserVerificationHelperFactory(),
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
            application: application,
            appSettingsStore: appSettingsStore,
            authRepository: authRepository,
            authService: authService,
            authenticatorSyncService: authenticatorSyncService,
            autofillCredentialService: autofillCredentialService,
            biometricsRepository: biometricsRepository,
            biometricsService: biometricsService,
            captchaService: captchaService,
            cameraService: cameraService,
            clientService: clientService,
            configService: configService,
            environmentService: environmentService,
            errorReporter: errorReporter,
            eventService: eventService,
            exportVaultService: exportVaultService,
            fido2CredentialStore: fido2CredentialStore,
            fido2UserInterfaceHelper: fido2UserInterfaceHelper,
            generatorRepository: generatorRepository,
            importCiphersRepository: importCiphersRepository,
            keychainRepository: keychainRepository,
            keychainService: keychainService,
            localAuthService: localAuthService,
            migrationService: migrationService,
            nfcReaderService: nfcReaderService,
            notificationCenterService: notificationCenterService,
            notificationService: notificationService,
            pasteboardService: pasteboardService,
            policyService: policyService,
            rehydrationHelper: rehydrationHelper,
            reviewPromptService: reviewPromptService,
            sendRepository: sendRepository,
            settingsRepository: settingsRepository,
            stateService: stateService,
            syncService: syncService,
            systemDevice: systemDevice,
            textAutofillHelperFactory: textAutofillHelperFactory,
            timeProvider: timeProvider,
            tokenService: tokenService,
            totpExpirationManagerFactory: totpExpirationManagerFactory,
            totpService: totpService,
            trustDeviceService: trustDeviceService,
            twoStepLoginService: twoStepLoginService,
            userVerificationHelperFactory: userVerificationHelperFactory,
            vaultRepository: vaultRepository,
            vaultTimeoutService: vaultTimeoutService,
            watchService: watchService
        )
    }
}
