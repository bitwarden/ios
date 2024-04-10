import BitwardenSdk
import Networking

@testable import AuthenticatorShared

extension ServiceContainer {
    static func withMocks(
        application: Application? = nil,
        authenticatorItemRepository: AuthenticatorItemRepository = MockAuthenticatorItemRepository(),
        cameraService: CameraService = MockCameraService(),
        clientService: ClientService = MockClientService(),
        cryptographyService: CryptographyService = MockCryptographyService(),
        errorReporter: ErrorReporter = MockErrorReporter(),
        pasteboardService: PasteboardService = MockPasteboardService(),
        timeProvider: TimeProvider = MockTimeProvider(.currentTime),
        totpService: TOTPService = MockTOTPService()
    ) -> ServiceContainer {
        ServiceContainer(
            application: application,
            authenticatorItemRepository: authenticatorItemRepository,
            cameraService: cameraService,
            cryptographyService: cryptographyService,
            clientService: clientService,
            errorReporter: errorReporter,
            pasteboardService: pasteboardService,
            timeProvider: timeProvider,
            totpService: totpService
        )
    }
}
