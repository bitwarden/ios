import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SwiftUI
import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - TabCoordinatorTests

class TabCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var errorReporter: MockErrorReporter!
    var module: MockAppModule!
    var policyService: MockPolicyService!
    var rootNavigator: MockRootNavigator!
    var settingsDelegate: MockSettingsCoordinatorDelegate!
    var subject: TabCoordinator!
    var tabNavigator: MockTabNavigator!
    var vaultDelegate: MockVaultCoordinatorDelegate!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        errorReporter = MockErrorReporter()
        module = MockAppModule()
        policyService = MockPolicyService()
        rootNavigator = MockRootNavigator()
        tabNavigator = MockTabNavigator()
        settingsDelegate = MockSettingsCoordinatorDelegate()
        vaultDelegate = MockVaultCoordinatorDelegate()
        vaultRepository = MockVaultRepository()
        subject = TabCoordinator(
            errorReporter: errorReporter,
            module: module,
            policyService: policyService,
            rootNavigator: rootNavigator,
            settingsDelegate: settingsDelegate,
            tabNavigator: tabNavigator,
            vaultDelegate: vaultDelegate,
            vaultRepository: vaultRepository,
        )
    }

    override func tearDown() {
        super.tearDown()
        errorReporter = nil
        module = nil
        policyService = nil
        rootNavigator = nil
        subject = nil
        tabNavigator = nil
        vaultDelegate = nil
        vaultRepository = nil
    }

    // MARK: Tests

    /// `navigate(to:)` with `.generator` sets the correct selected index on tab navigator.
    @MainActor
    func test_navigate_generator() {
        subject.navigate(to: .generator(.generator()))
        XCTAssertEqual(tabNavigator.selectedIndex, 2)
    }

    /// When `disableSend` policy applies, `navigate(to: .generator)` uses visual index 1 (Send tab absent).
    @MainActor
    func test_navigate_generator_sendHidden_usesAdjustedIndex() {
        policyService.policyAppliesToUserResult[.disableSend] = true
        subject.start()
        waitFor { self.tabNavigator.navigators.count == 3 }

        subject.navigate(to: .generator(.generator()))

        XCTAssertEqual(tabNavigator.selectedIndex, 1)
    }

    /// `navigate(to:)` with `.send` sets the correct selected index on tab navigator.
    @MainActor
    func test_navigate_send() {
        subject.navigate(to: .send)
        XCTAssertEqual(tabNavigator.selectedIndex, 1)
    }

    /// When `disableSend` policy applies, `navigate(to: .send)` is ignored and `selectedIndex` is unchanged.
    @MainActor
    func test_navigate_send_whenPolicyActive_isIgnored() {
        policyService.policyAppliesToUserResult[.disableSend] = true
        subject.start()
        waitFor { self.tabNavigator.navigators.count == 3 }

        tabNavigator.selectedIndex = 0
        subject.navigate(to: .send)

        XCTAssertEqual(tabNavigator.selectedIndex, 0)
    }

    /// `navigate(to:)` with `.settings` sets the correct selected index on tab navigator.
    @MainActor
    func test_navigate_settings() {
        subject.start()
        subject.navigate(to: .settings(.settings(.tab)))
        XCTAssertEqual(tabNavigator.selectedIndex, 3)
        XCTAssertEqual(module.settingsCoordinator.routes, [.settings(.tab)])
    }

    /// When `disableSend` policy applies, `navigate(to: .settings)` uses visual index 2 (Send tab absent).
    @MainActor
    func test_navigate_settings_sendHidden_usesAdjustedIndex() {
        policyService.policyAppliesToUserResult[.disableSend] = true
        subject.start()
        waitFor { self.tabNavigator.navigators.count == 3 }

        subject.navigate(to: .settings(.settings(.tab)))

        XCTAssertEqual(tabNavigator.selectedIndex, 2)
    }

    /// `navigate(to:)` with `.vault(.list)` sets the correct selected index on tab navigator.
    @MainActor
    func test_navigate_vault() {
        subject.navigate(to: .vault(.list))
        XCTAssertEqual(tabNavigator.selectedIndex, 0)
    }

    /// `rootNavigator` uses a weak reference and does not retain a value once the root navigator has been erased.
    @MainActor
    func test_rootNavigator_resetWeakReference() {
        var rootNavigator: MockRootNavigator? = MockRootNavigator()
        subject = TabCoordinator(
            errorReporter: errorReporter,
            module: module,
            policyService: policyService,
            rootNavigator: rootNavigator!,
            settingsDelegate: MockSettingsCoordinatorDelegate(),
            tabNavigator: tabNavigator,
            vaultDelegate: MockVaultCoordinatorDelegate(),
            vaultRepository: vaultRepository,
        )
        XCTAssertNotNil(subject.rootNavigator)

        rootNavigator = nil
        XCTAssertNil(subject.rootNavigator)
    }

    /// `showLoadingOverlay()` and `hideLoadingOverlay()` can be used to show and hide the loading overlay.
    @MainActor
    func test_show_hide_loadingOverlay() throws {
        tabNavigator.rootViewController = UIViewController()
        try setKeyWindowRoot(viewController: XCTUnwrap(subject.tabNavigator?.rootViewController))

        XCTAssertNil(window.viewWithTag(LoadingOverlayDisplayHelper.overlayViewTag))

        subject.showLoadingOverlay(LoadingOverlayState(title: "Loading..."))
        XCTAssertNotNil(window.viewWithTag(LoadingOverlayDisplayHelper.overlayViewTag))

        subject.hideLoadingOverlay()
        waitFor { window.viewWithTag(LoadingOverlayDisplayHelper.overlayViewTag) == nil }
        XCTAssertNil(window.viewWithTag(LoadingOverlayDisplayHelper.overlayViewTag))
    }

    /// `start()` presents the tab navigator within the root navigator and starts the child-coordinators.
    @MainActor
    func test_start_noOrganizations() {
        let mockRoot = MockRootNavigator()
        let viewController = UIViewController()
        mockRoot.rootViewController = viewController
        tabNavigator.navigatorForTabReturns = mockRoot
        vaultRepository.organizationsSubject = .init([])
        subject.start()
        XCTAssertIdentical(rootNavigator.navigatorShown, tabNavigator)

        // Placeholder assertion until the vault screen is added: BIT-218
        XCTAssertTrue(tabNavigator.navigators[0] is StackNavigator)

        // Placeholder assertion until the send screen is added: BIT-249
        XCTAssertTrue(tabNavigator.navigators[1] is StackNavigator)

        XCTAssertTrue(tabNavigator.navigators[2] is StackNavigator)
        XCTAssertTrue(module.generatorCoordinator.isStarted)

        XCTAssertTrue(tabNavigator.navigators[3] is StackNavigator)
        XCTAssertTrue(module.settingsCoordinator.isStarted)

        waitFor(vaultRepository.organizationsPublisherCalled)
        waitFor(viewController.title != nil)
        XCTAssertEqual(viewController.title, Localizations.myVault)
    }

    /// `start()` presents the tab navigator within the root navigator and starts the child-coordinators.
    @MainActor
    func test_start_organizations() {
        let mockRoot = MockRootNavigator()
        let viewController = UIViewController()
        mockRoot.rootViewController = viewController
        tabNavigator.navigatorForTabReturns = mockRoot
        vaultRepository.organizationsSubject = .init([
            .fixture(),
        ])
        subject.start()
        XCTAssertIdentical(rootNavigator.navigatorShown, tabNavigator)

        // Placeholder assertion until the vault screen is added: BIT-218
        XCTAssertTrue(tabNavigator.navigators[0] is StackNavigator)

        // Placeholder assertion until the send screen is added: BIT-249
        XCTAssertTrue(tabNavigator.navigators[1] is StackNavigator)

        XCTAssertTrue(tabNavigator.navigators[2] is StackNavigator)
        XCTAssertTrue(module.generatorCoordinator.isStarted)

        XCTAssertTrue(tabNavigator.navigators[3] is StackNavigator)
        XCTAssertTrue(module.settingsCoordinator.isStarted)

        waitFor(vaultRepository.organizationsPublisherCalled)
        waitFor(viewController.title != nil)
        XCTAssertEqual(viewController.title, Localizations.vaults)
    }

    /// `start()` subscribes to the organization publisher and updates the vault navigation bar
    /// title if the vault filter can't be shown.
    @MainActor
    func test_start_organizationsCanShowVaultFilterDisabled() {
        let mockRoot = MockRootNavigator()
        let viewController = UIViewController()
        mockRoot.rootViewController = viewController
        tabNavigator.navigatorForTabReturns = mockRoot
        vaultRepository.canShowVaultFilter = false
        vaultRepository.organizationsSubject = .init([
            .fixture(),
        ])

        subject.start()

        waitFor(viewController.title != nil)
        XCTAssertEqual(viewController.title, Localizations.myVault)
    }

    /// `start()` presents the tab navigator within the root navigator and starts the child-coordinators.
    @MainActor
    func test_start_organizationsError() throws {
        let mockRoot = MockRootNavigator()
        let viewController = UIViewController()
        mockRoot.rootViewController = viewController
        tabNavigator.navigatorForTabReturns = mockRoot
        let expectedError = BitwardenTestError.example
        vaultRepository.organizationsPublisherError = expectedError
        subject.start()
        XCTAssertIdentical(rootNavigator.navigatorShown, tabNavigator)

        // Placeholder assertion until the vault screen is added: BIT-218
        XCTAssertTrue(tabNavigator.navigators[0] is StackNavigator)

        // Placeholder assertion until the send screen is added: BIT-249
        XCTAssertTrue(tabNavigator.navigators[1] is StackNavigator)

        XCTAssertTrue(tabNavigator.navigators[2] is StackNavigator)
        XCTAssertTrue(module.generatorCoordinator.isStarted)

        XCTAssertTrue(tabNavigator.navigators[3] is StackNavigator)
        XCTAssertTrue(module.settingsCoordinator.isStarted)

        waitFor(!errorReporter.errors.isEmpty)
        let error = try XCTUnwrap(errorReporter.errors.first as? BitwardenTestError)
        XCTAssertEqual(error, expectedError)
    }

    /// The organization stream reactively updates the Send tab visibility when the policy changes mid-session.
    @MainActor
    func test_start_organizationStream_updatesSendTabVisibility() {
        let mockRoot = MockRootNavigator()
        mockRoot.rootViewController = UIViewController()
        tabNavigator.navigatorForTabReturns = mockRoot
        policyService.policyAppliesToUserResult[.disableSend] = false
        vaultRepository.organizationsSubject = .init([])

        subject.start()
        // start() calls updateTabs(isSendEnabled: true) synchronously — 4 tabs immediately.
        XCTAssertEqual(tabNavigator.navigators.count, 4)

        // Simulate an org stream event while the policy is now active.
        policyService.policyAppliesToUserResult[.disableSend] = true
        vaultRepository.organizationsSubject.send([])

        waitFor { self.tabNavigator.navigators.count == 3 }
        XCTAssertEqual(tabNavigator.navigators.count, 3)
    }

    /// `start()` shows all four tabs when `disableSend` policy does not apply.
    @MainActor
    func test_start_sendTabShown_whenDisableSendPolicyNotApplied() {
        policyService.policyAppliesToUserResult[.disableSend] = false
        subject.start()

        // updateTabs(isSendEnabled: true) is called synchronously in start(), so count is 4 immediately.
        XCTAssertEqual(tabNavigator.navigators.count, 4)
    }

    /// `start()` hides the Send tab when `disableSend` policy applies to the user.
    @MainActor
    func test_start_sendTabHidden_whenDisableSendPolicyApplies() {
        policyService.policyAppliesToUserResult[.disableSend] = true
        subject.start()

        // start() calls updateTabs(isSendEnabled: true) synchronously first, then the async
        // policy Task updates it to isSendEnabled: false.
        waitFor { self.tabNavigator.navigators.count == 3 }

        XCTAssertEqual(tabNavigator.navigators.count, 3)
    }
}
