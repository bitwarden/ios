import XCTest

@testable import BitwardenShared

// MARK: - TwoFactorNoticeHelperTests

class TwoFactorNoticeHelperTests: BitwardenTestCase {
    // MARK: Properties

    var configService: MockConfigService!
    var coordinator: MockCoordinator<VaultRoute, AuthAction>!
    var environmentService: MockEnvironmentService!
    var errorReporter: MockErrorReporter!
    var policyService: MockPolicyService!
    var stateService: MockStateService!
    var subject: DefaultTwoFactorNoticeHelper!
    var timeProvider: MockTimeProvider!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        configService = MockConfigService()
        coordinator = MockCoordinator()
        environmentService = MockEnvironmentService()
        errorReporter = MockErrorReporter()
        policyService = MockPolicyService()
        stateService = MockStateService()
        timeProvider = MockTimeProvider(.mockTime(Date(year: 2024, month: 6, day: 15, hour: 12, minute: 0)))

        let services = ServiceContainer.withMocks(
            configService: configService,
            environmentService: environmentService,
            errorReporter: errorReporter,
            policyService: policyService,
            stateService: stateService,
            timeProvider: timeProvider
        )

        subject = DefaultTwoFactorNoticeHelper(
            coordinator: coordinator.asAnyCoordinator(),
            services: services
        )

        // Because nearly all of the tests are "it doesn't show the notice if
        // these conditions are true", it makes sense to set things up here to
        // show the notice, and then in tests selectively set up the specific
        // condition that causes it to not show. This hopefully makes the tests
        // easier to read.
        stateService.activeAccount = .fixture(
            profile: .fixture(twoFactorEnabled: false)
        )
        configService.featureFlagsBool[.newDeviceVerificationTemporaryDismiss] = true
        configService.featureFlagsBool[.newDeviceVerificationPermanentDismiss] = true
        environmentService.region = .unitedStates
        policyService.policyAppliesToUserResult[.requireSSO] = false
    }

    override func tearDown() {
        super.tearDown()

        configService = nil
        coordinator = nil
        environmentService = nil
        errorReporter = nil
        policyService = nil
        stateService = nil
        subject = nil
        timeProvider = nil
    }

    // MARK: Tests based on properties of the account itself

    /// `.maybeShowTwoFactorNotice()` will show the notice
    /// if the user does not have a 2FA method configured,
    /// is not self-hosted
    /// and is not SSO-only
    ///
    @MainActor
    func test_maybeShow() async {
        await subject.maybeShowTwoFactorNotice()

        XCTAssertEqual(coordinator.routes, [.twoFactorNotice(allowDelay: false, emailAddress: "user@bitwarden.com")])
    }

    /// `.maybeShowTwoFactorNotice()` will not show the notice
    /// if the user already has a 2FA method configured
    @MainActor
    func test_maybeShow_preexistingTwoFactor() async {
        stateService.activeAccount?.profile.twoFactorEnabled = true

        await subject.maybeShowTwoFactorNotice()

        XCTAssertEqual(coordinator.routes, [])
    }

    /// `.maybeShowTwoFactorNotice()` will show the notice
    /// if the user is in the Europe region
    @MainActor
    func test_maybeShow_server_europe() async {
        environmentService.region = .europe

        await subject.maybeShowTwoFactorNotice()

        XCTAssertEqual(coordinator.routes, [.twoFactorNotice(allowDelay: false, emailAddress: "user@bitwarden.com")])
    }

    /// `.maybeShowTwoFactorNotice()` will not show the notice
    /// if the user is self-hosted
    @MainActor
    func test_maybeShow_server_selfHosted() async {
        environmentService.region = .selfHosted

        await subject.maybeShowTwoFactorNotice()

        XCTAssertEqual(coordinator.routes, [])
    }

    /// `.maybeShowTwoFactorNotice()` will not show the notice
    /// if the user is SSO-only
    ///
    /// policyService.policyAppliesToUser(.requresSso)
    @MainActor
    func test_maybeShow_ssoOnly() async {
        policyService.policyAppliesToUserResult[.requireSSO] = true

        await subject.maybeShowTwoFactorNotice()

        XCTAssertEqual(coordinator.routes, [])
    }

    // MARK: Tests based on feature flags and notice display state

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
        configService.featureFlagsBool[.newDeviceVerificationTemporaryDismiss] = false
        configService.featureFlagsBool[.newDeviceVerificationPermanentDismiss] = true
        stateService.twoFactorNoticeDisplayState["1"] = .canAccessEmail

        await subject.maybeShowTwoFactorNotice()

        XCTAssertEqual(coordinator.routes, [.twoFactorNotice(allowDelay: false, emailAddress: "user@bitwarden.com")])
    }

    /// `.maybeShowTwoFactorNotice()` will not show the notice
    /// if the user indicated they can access the email in permanent mode
    @MainActor
    func test_maybeShow_canAccessEmailPermanent() async {
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
        configService.featureFlagsBool[.newDeviceVerificationTemporaryDismiss] = false
        configService.featureFlagsBool[.newDeviceVerificationPermanentDismiss] = true
        stateService.twoFactorNoticeDisplayState["1"] = .hasNotSeen

        await subject.maybeShowTwoFactorNotice()

        XCTAssertEqual(coordinator.routes, [.twoFactorNotice(allowDelay: false, emailAddress: "user@bitwarden.com")])
    }

    /// `.maybeShowTwoFactorNotice()` will show the notice
    /// if the user has not seen it
    @MainActor
    func test_maybeShow_hasNotSeen_temporary() async {
        configService.featureFlagsBool[.newDeviceVerificationTemporaryDismiss] = true
        configService.featureFlagsBool[.newDeviceVerificationPermanentDismiss] = false
        stateService.twoFactorNoticeDisplayState["1"] = .hasNotSeen

        await subject.maybeShowTwoFactorNotice()

        XCTAssertEqual(coordinator.routes, [.twoFactorNotice(allowDelay: true, emailAddress: "user@bitwarden.com")])
    }

    /// `.maybeShowTwoFactorNotice()` will not show the notice
    /// if the user last saw it less than seven days ago
    @MainActor
    func test_maybeShow_seenLessThenSevenDays() async {
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
        configService.featureFlagsBool[.newDeviceVerificationTemporaryDismiss] = true
        configService.featureFlagsBool[.newDeviceVerificationPermanentDismiss] = false
        stateService.twoFactorNoticeDisplayState["1"] = .seen(Date(year: 2024, month: 6, day: 8, hour: 11, minute: 59))
        environmentService.region = .unitedStates

        await subject.maybeShowTwoFactorNotice()

        XCTAssertEqual(coordinator.routes, [.twoFactorNotice(allowDelay: true, emailAddress: "user@bitwarden.com")])
    }

    // MARK: Other tests

    /// `.maybeShowTwoFactorNotice()` handles errors
    @MainActor
    func test_maybeShow_error() async {
        stateService.twoFactorNoticeDisplayStateError = BitwardenTestError.example

        await subject.maybeShowTwoFactorNotice()

        XCTAssertEqual(
            errorReporter.errors.last as? BitwardenTestError,
            BitwardenTestError.example
        )
        XCTAssertEqual(coordinator.routes, [])
    }
}
