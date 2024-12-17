import XCTest

@testable import BitwardenShared

// MARK: - TwoFactorNoticeHelperTests

class TwoFactorNoticeHelperTests: BitwardenTestCase {
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var coordinator: MockCoordinator<VaultRoute, AuthAction>!
    var errorReporter: MockErrorReporter!
    var pasteboardService: MockPasteboardService!
    var stateService: MockStateService!
    var subject: VaultItemMoreOptionsHelper!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        authRepository = MockAuthRepository()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        pasteboardService = MockPasteboardService()
        stateService = MockStateService()
        vaultRepository = MockVaultRepository()

        subject = DefaultVaultItemMoreOptionsHelper(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                errorReporter: errorReporter,
                pasteboardService: pasteboardService,
                stateService: stateService,
                vaultRepository: vaultRepository
            )
        )
    }

    override func tearDown() {
        super.tearDown()

        authRepository = nil
        coordinator = nil
        errorReporter = nil
        pasteboardService = nil
        stateService = nil
        subject = nil
        vaultRepository = nil
    }

    // MARK: Tests
}
