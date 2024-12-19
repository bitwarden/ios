import XCTest

@testable import BitwardenShared

// MARK: - TwoFactorNoticeHelperTests

class TwoFactorNoticeHelperTests: BitwardenTestCase {
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var configService: MockConfigService!
    var coordinator: MockCoordinator<VaultRoute, AuthAction>!
    var errorReporter: MockErrorReporter!
    var pasteboardService: MockPasteboardService!
    var stateService: MockStateService!
    var subject: DefaultTwoFactorNoticeHelper!
    var timeProvider: MockTimeProvider!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        authRepository = MockAuthRepository()
        configService = MockConfigService()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        pasteboardService = MockPasteboardService()
        stateService = MockStateService()
        timeProvider = MockTimeProvider(.mockTime(Date(year: 2024, month: 6, day: 15, hour: 12, minute: 0)))
        vaultRepository = MockVaultRepository()

        let services = ServiceContainer.withMocks(
            authRepository: authRepository,
            configService: configService,
            errorReporter: errorReporter,
            pasteboardService: pasteboardService,
            stateService: stateService,
            timeProvider: timeProvider,
            vaultRepository: vaultRepository
        )

        subject = DefaultTwoFactorNoticeHelper(
            coordinator: coordinator.asAnyCoordinator(),
            services: services
        )
    }

    override func tearDown() {
        super.tearDown()

        authRepository = nil
        configService = nil
        coordinator = nil
        errorReporter = nil
        pasteboardService = nil
        stateService = nil
        subject = nil
        vaultRepository = nil
    }

    // MARK: Tests

    /// `.maybeShowTwoFactorNotice()` will not show the notice if both feature flags are off.
    @MainActor
    func test_maybeShow_neitherFeatureFlag() async {
        configService.featureFlagsBool[.newDeviceVerificationTemporaryDismiss] = false
        configService.featureFlagsBool[.newDeviceVerificationPermanentDismiss] = false

        await subject.maybeShowTwoFactorNotice()

        XCTAssertEqual(coordinator.routes, [])
    }

    /// `.maybeShowTwoFactorNotice()` will not show the notice
    /// if the user indicated they can access the email in temporary mode
    /// and we are still in temporary mode
    @MainActor
    func test_maybeShow_canAccessEmail_temporary() async {
        stateService.activeAccount = .fixture()
        configService.featureFlagsBool[.newDeviceVerificationTemporaryDismiss] = true
        configService.featureFlagsBool[.newDeviceVerificationPermanentDismiss] = false
        stateService.twoFactorNoticeDisplayState["1"] = .canAccessEmail

        await subject.maybeShowTwoFactorNotice()

        XCTAssertEqual(coordinator.routes, [])
    }

    /// `.maybeShowTwoFactorNotice()` will show the notice
    /// if the user indicated they can access the email in temporary mode
    /// and we are in permanent mode
    @MainActor
    func test_maybeShow_canAccessEmail_permanent() async {
        stateService.activeAccount = .fixture()
        configService.featureFlagsBool[.newDeviceVerificationTemporaryDismiss] = true
        configService.featureFlagsBool[.newDeviceVerificationPermanentDismiss] = true
        stateService.twoFactorNoticeDisplayState["1"] = .canAccessEmail

        await subject.maybeShowTwoFactorNotice()

        XCTAssertEqual(coordinator.routes, [.twoFactorNotice(false)])
    }

    /// `.maybeShowTwoFactorNotice()` will not show the notice
    /// if the user indicated they can access the email in permanent mode
    @MainActor
    func test_maybeShow_canAccessEmailPermanent() async {
        stateService.activeAccount = .fixture()
        configService.featureFlagsBool[.newDeviceVerificationTemporaryDismiss] = true
        configService.featureFlagsBool[.newDeviceVerificationPermanentDismiss] = true
        stateService.twoFactorNoticeDisplayState["1"] = .canAccessEmailPermanent

        await subject.maybeShowTwoFactorNotice()

        XCTAssertEqual(coordinator.routes, [])
    }

    /// `.maybeShowTwoFactorNotice()` will show the notice
    /// if the user has not seen it
    @MainActor
    func test_maybeShow_hasNotSeen_permanent() async {
        stateService.activeAccount = .fixture()
        configService.featureFlagsBool[.newDeviceVerificationTemporaryDismiss] = false
        configService.featureFlagsBool[.newDeviceVerificationPermanentDismiss] = true
        stateService.twoFactorNoticeDisplayState["1"] = .hasNotSeen

        await subject.maybeShowTwoFactorNotice()

        XCTAssertEqual(coordinator.routes, [.twoFactorNotice(false)])
    }

    /// `.maybeShowTwoFactorNotice()` will show the notice
    /// if the user has not seen it
    @MainActor
    func test_maybeShow_hasNotSeen_temporary() async {
        stateService.activeAccount = .fixture()
        configService.featureFlagsBool[.newDeviceVerificationTemporaryDismiss] = true
        configService.featureFlagsBool[.newDeviceVerificationPermanentDismiss] = false
        stateService.twoFactorNoticeDisplayState["1"] = .hasNotSeen

        await subject.maybeShowTwoFactorNotice()

        XCTAssertEqual(coordinator.routes, [.twoFactorNotice(true)])
    }

    /// `.maybeShowTwoFactorNotice()` will not show the notice
    /// if the user last saw it less than seven days ago
    @MainActor
    func test_maybeShow_seenLessThenSevenDays() async {
        stateService.activeAccount = .fixture()
        configService.featureFlagsBool[.newDeviceVerificationTemporaryDismiss] = true
        configService.featureFlagsBool[.newDeviceVerificationPermanentDismiss] = false
        stateService.twoFactorNoticeDisplayState["1"] = .seen(Date(year: 2024, month: 6, day: 8, hour: 12, minute: 1))

        await subject.maybeShowTwoFactorNotice()

        XCTAssertEqual(coordinator.routes, [])
    }

    /// `.maybeShowTwoFactorNotice()` will show the notice
    /// if the user last saw it more than seven days ago
    @MainActor
    func test_maybeShow_seenMoreThenSevenDays() async {
        stateService.activeAccount = .fixture()
        configService.featureFlagsBool[.newDeviceVerificationTemporaryDismiss] = true
        configService.featureFlagsBool[.newDeviceVerificationPermanentDismiss] = false
        stateService.twoFactorNoticeDisplayState["1"] = .seen(Date(year: 2024, month: 6, day: 8, hour: 11, minute: 59))

        await subject.maybeShowTwoFactorNotice()

        XCTAssertEqual(coordinator.routes, [.twoFactorNotice(true)])
    }

    /// `.maybeShowTwoFactorNotice()` handles errors
    @MainActor
    func test_maybeShow_error() async {
        stateService.activeAccount = .fixture()
        configService.featureFlagsBool[.newDeviceVerificationTemporaryDismiss] = true
        configService.featureFlagsBool[.newDeviceVerificationPermanentDismiss] = false
        stateService.twoFactorNoticeDisplayStateError = BitwardenTestError.example

        await subject.maybeShowTwoFactorNotice()

        XCTAssertEqual(
            errorReporter.errors.last as? BitwardenTestError,
            BitwardenTestError.example
        )
        XCTAssertEqual(coordinator.routes, [])
    }
}
