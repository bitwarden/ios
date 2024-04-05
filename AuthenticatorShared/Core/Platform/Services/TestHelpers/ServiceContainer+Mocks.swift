import BitwardenSdk
import Networking

@testable import AuthenticatorShared

extension ServiceContainer {
    static func withMocks(
        application: Application? = nil,
        cameraService: CameraService = MockCameraService(),
        clientService: ClientService = MockClientService(),
        errorReporter: ErrorReporter = MockErrorReporter(),
        pasteboardService: PasteboardService = MockPasteboardService(),
        timeProvider: TimeProvider = MockTimeProvider(.currentTime),
        tokenRepository: TokenRepository = MockTokenRepository(),
        totpService: TOTPService = MockTOTPService()
    ) -> ServiceContainer {
        ServiceContainer(
            application: application,
            cameraService: cameraService,
            clientService: clientService,
            errorReporter: errorReporter,
            pasteboardService: pasteboardService,
            timeProvider: timeProvider, 
            tokenRepository: tokenRepository,
            totpService: totpService
        )
    }
}
