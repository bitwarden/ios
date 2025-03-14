import BitwardenSdk
import Networking

@testable import AuthenticatorShared

extension ServiceContainer {
    static func withMocks(
        application: Application? = nil,
        appSettingsStore: AppSettingsStore = MockAppSettingsStore(),
        authenticatorItemRepository: AuthenticatorItemRepository = MockAuthenticatorItemRepository(),
        biometricsRepository: BiometricsRepository = MockBiometricsRepository(),
        biometricsService: BiometricsService = MockBiometricsService(),
        cameraService: CameraService = MockCameraService(),
        clientService: ClientService = MockClientService(),
        configService: ConfigService = MockConfigService(),
        cryptographyService: CryptographyService = MockCryptographyService(),
        errorReporter: ErrorReporter = MockErrorReporter(),
        exportItemsService: ExportItemsService = MockExportItemsService(),
        importItemsService: ImportItemsService = MockImportItemsService(),
        migrationService: MigrationService = MockMigrationService(),
        notificationCenterService: NotificationCenterService = MockNotificationCenterService(),
        pasteboardService: PasteboardService = MockPasteboardService(),
        stateService: StateService = MockStateService(),
        timeProvider: TimeProvider = MockTimeProvider(.currentTime),
        totpService: TOTPService = MockTOTPService()
    ) -> ServiceContainer {
        ServiceContainer(
            application: application,
            appSettingsStore: appSettingsStore,
            authenticatorItemRepository: authenticatorItemRepository,
            biometricsRepository: biometricsRepository,
            biometricsService: biometricsService,
            cameraService: cameraService,
            clientService: clientService,
            configService: configService,
            cryptographyService: cryptographyService,
            errorReporter: errorReporter,
            exportItemsService: exportItemsService,
            importItemsService: importItemsService,
            migrationService: migrationService,
            notificationCenterService: notificationCenterService,
            pasteboardService: pasteboardService,
            stateService: stateService,
            timeProvider: timeProvider,
            totpService: totpService
        )
    }
}
