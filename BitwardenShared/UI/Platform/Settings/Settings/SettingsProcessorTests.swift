import XCTest

@testable import BitwardenShared

class SettingsProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var configService: MockConfigService!
    var coordinator: MockCoordinator<SettingsRoute, SettingsEvent>!
    var delegate: MockSettingsProcessorDelegate!
    var errorReporter: MockErrorReporter!
    var subject: SettingsProcessor!
    var stateService: MockStateService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        configService = MockConfigService()
        coordinator = MockCoordinator()
        delegate = MockSettingsProcessorDelegate()
        errorReporter = MockErrorReporter()
        stateService = MockStateService()

        setUpSubject()
    }

    override func tearDown() {
        super.tearDown()

        configService = nil
        coordinator = nil
        delegate = nil
        errorReporter = nil
        subject = nil
        stateService = nil
    }

    @MainActor
    func setUpSubject() {
        subject = SettingsProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            services: ServiceContainer.withMocks(
                configService: configService,
                errorReporter: errorReporter,
                stateService: stateService
            ),
            state: SettingsState()
        )
    }

    // MARK: Tests

    /// `init()` subscribes to the badge publisher and notifies the delegate to update the badge
    /// count when it changes.
    @MainActor
    func test_init_subscribesToBadgePublisher() async throws {
        configService.featureFlagsBool[.nativeCreateAccountFlow] = true
        stateService.activeAccount = .fixture()
        setUpSubject()

        var badgeState = SettingsBadgeState.fixture(badgeValue: "1", vaultUnlockSetupProgress: .setUpLater)
        stateService.settingsBadgeSubject.send(badgeState)
        try await waitForAsync { self.delegate.badgeValue == "1" }
        XCTAssertEqual(delegate.badgeValue, "1")
        XCTAssertEqual(subject.state.badgeState, badgeState)

        badgeState = SettingsBadgeState.fixture(
            autofillSetupProgress: .setUpLater,
            badgeValue: "2",
            vaultUnlockSetupProgress: .setUpLater
        )
        stateService.settingsBadgeSubject.send(badgeState)
        try await waitForAsync { self.delegate.badgeValue == "2" }
        XCTAssertEqual(delegate.badgeValue, "2")
        XCTAssertEqual(subject.state.badgeState, badgeState)

        badgeState = SettingsBadgeState.fixture(badgeValue: nil)
        stateService.settingsBadgeSubject.send(badgeState)
        try await waitForAsync { self.delegate.badgeValue == nil }
        XCTAssertNil(delegate.badgeValue)
        XCTAssertEqual(subject.state.badgeState, badgeState)
    }

    /// `init()` subscribes to the badge publisher and logs an error if one occurs.
    @MainActor
    func test_init_subscribesToBadgePublisher_error() async throws {
        configService.featureFlagsBool[.nativeCreateAccountFlow] = true
        setUpSubject()

        stateService.settingsBadgeSubject.send(SettingsBadgeState.fixture(badgeValue: "1"))
        try await waitForAsync { !self.errorReporter.errors.isEmpty }

        XCTAssertEqual(errorReporter.errors as? [StateServiceError], [.noActiveAccount])
    }

    /// Receiving `.aboutPressed` navigates to the about screen.
    @MainActor
    func test_receive_aboutPressed() {
        subject.receive(.aboutPressed)

        XCTAssertEqual(coordinator.routes.last, .about)
    }

    /// Receiving `.accountSecurityPressed` navigates to the account security screen.
    @MainActor
    func test_receive_accountSecurityPressed() {
        subject.receive(.accountSecurityPressed)

        XCTAssertEqual(coordinator.routes.last, .accountSecurity)
    }

    /// Receiving `.appearancePressed` navigates to the appearance screen.
    @MainActor
    func test_receive_appearancePressed() {
        subject.receive(.appearancePressed)

        XCTAssertEqual(coordinator.routes.last, .appearance)
    }

    /// Receiving `.autoFillPressed` navigates to the auto-fill screen.
    @MainActor
    func test_receive_autoFillPressed() {
        subject.receive(.autoFillPressed)

        XCTAssertEqual(coordinator.routes.last, .autoFill)
    }

    /// Receiving `.otherPressed` navigates to the other screen.
    @MainActor
    func test_receive_otherPressed() {
        subject.receive(.otherPressed)

        XCTAssertEqual(coordinator.routes.last, .other)
    }

    /// Receiving `.vaultPressed` navigates to the vault settings screen.
    @MainActor
    func test_receive_vaultPressed() {
        subject.receive(.vaultPressed)

        XCTAssertEqual(coordinator.routes.last, .vault)
    }
}

class MockSettingsProcessorDelegate: SettingsProcessorDelegate {
    var badgeValue: String?

    func updateSettingsTabBadge(_ badgeValue: String?) {
        self.badgeValue = badgeValue
    }
}
