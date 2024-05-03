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
        cryptographyService: CryptographyService = MockCryptographyService(),
        errorReporter: ErrorReporter = MockErrorReporter(),
        exportItemsService: ExportItemsService = MockExportItemsService(),
        importItemsService: ImportItemsService = MockImportItemsService(),
        migrationService: MigrationService = MockMigrationService(),
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
            cryptographyService: cryptographyService,
            clientService: clientService,
            errorReporter: errorReporter,
            exportItemsService: exportItemsService,
            importItemsService: importItemsService,
            migrationService: migrationService,
            pasteboardService: pasteboardService,
            stateService: stateService,
            timeProvider: timeProvider,
            totpService: totpService
        )
    }
}
