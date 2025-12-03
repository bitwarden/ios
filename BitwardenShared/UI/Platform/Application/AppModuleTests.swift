import BitwardenKit
import BitwardenKitMocks
import SwiftUI
import TestHelpers
import XCTest

@testable import BitwardenShared

class AppModuleTests: BitwardenTestCase {
    // MARK: Properties

    var rootViewController: RootViewController!
    var subject: DefaultAppModule!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        rootViewController = RootViewController()
        subject = DefaultAppModule(services: .withMocks())
    }

    override func tearDown() {
        super.tearDown()

        rootViewController = nil
        subject = nil
    }

    // MARK: Tests

    /// `makeAddEditFolderCoordinator` builds the add/edit folder coordinator.
    @MainActor
    func test_makeAddEditFolderCoordinator() {
        let navigationController = UINavigationController()
        let coordinator = subject.makeAddEditFolderCoordinator(stackNavigator: navigationController)
        coordinator.navigate(to: .addEditFolder(folder: nil))
        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertTrue(navigationController.viewControllers[0] is UIHostingController<AddEditFolderView>)
    }

    /// `makeAppCoordinator` builds the app coordinator.
    @MainActor
    func test_makeAppCoordinator() {
        let coordinator = subject.makeAppCoordinator(appContext: .mainApp, navigator: rootViewController)
        coordinator.navigate(to: .auth(.landing), context: nil)
        XCTAssertNotNil(rootViewController.childViewController)
    }

    /// `makeAuthCoordinator` builds the auth coordinator.
    @MainActor
    func test_makeAuthCoordinator() {
        let navigationController = UINavigationController()
        let coordinator = subject.makeAuthCoordinator(
            delegate: MockAuthDelegate(),
            rootNavigator: rootViewController,
            stackNavigator: navigationController,
        )
        coordinator.start()
        XCTAssertNotNil(rootViewController.childViewController)
        XCTAssertTrue(rootViewController.childViewController === navigationController)
    }

    /// `makeDebugMenuCoordinator()` builds the debug menu coordinator.
    @MainActor
    func test_makeDebugMenuCoordinator() {
        let navigationController = UINavigationController()
        let coordinator = subject.makeDebugMenuCoordinator(
            delegate: MockDebugMenuCoordinatorDelegate(),
            stackNavigator: navigationController,
        )
        coordinator.start()
        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertTrue(navigationController.viewControllers[0] is UIHostingController<DebugMenuView>)
    }

    /// `makeExportCXFCoordinator(stackNavigator:)` builds the Credential Exchange export coordinator.
    @MainActor
    func test_makeExportCXFCoordinator() {
        let navigationController = UINavigationController()
        let coordinator = subject.makeExportCXFCoordinator(
            stackNavigator: navigationController,
        )
        coordinator.start()
        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertTrue(navigationController.viewControllers[0] is UIHostingController<ExportCXFView>)
    }

    /// `makeExtensionSetupCoordinator` builds the extensions setup coordinator.
    @MainActor
    func test_makeExtensionSetupCoordinator() {
        let navigationController = UINavigationController()
        let coordinator = subject.makeExtensionSetupCoordinator(
            stackNavigator: navigationController,
        )
        coordinator.navigate(to: .extensionActivation(type: .autofillExtension))
        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertTrue(navigationController.viewControllers[0] is UIHostingController<ExtensionActivationView>)
    }

    /// `makeImportLoginsCoordinator` builds the import logins coordinator.
    @MainActor
    func test_makeImportLoginsCoordinator() {
        let navigationController = UINavigationController()
        let coordinator = subject.makeImportLoginsCoordinator(
            delegate: MockImportLoginsCoordinatorDelegate(),
            stackNavigator: navigationController,
        )
        coordinator.navigate(to: .importLogins(.vault))
        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertTrue(navigationController.viewControllers[0] is UIHostingController<ImportLoginsView>)
    }

    /// `makeNavigationController()` builds a navigation controller.
    @MainActor
    func test_makeNavigationController() {
        let navigationController = subject.makeNavigationController()
        XCTAssertTrue(navigationController is ViewLoggingNavigationController)
    }

    /// `makePasswordAutoFillCoordinator` builds the password autofill coordinator.
    @MainActor
    func test_makePasswordAutoFillCoordinator() {
        let navigationController = UINavigationController()
        let coordinator = subject.makePasswordAutoFillCoordinator(
            delegate: MockPasswordAutoFillCoordinatorDelegate(),
            stackNavigator: navigationController,
        )
        coordinator.navigate(to: .passwordAutofill(mode: .onboarding))
        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertTrue(navigationController.viewControllers[0] is UIHostingController<PasswordAutoFillView>)
    }

    /// `makeSelectLanguageCoordinator()` builds the select language coordinator.
    @MainActor
    func test_makeSelectLanguageCoordinator() throws {
        let navigationController = MockStackNavigator()
        let coordinator = subject.makeSelectLanguageCoordinator(
            stackNavigator: navigationController,
        )
        coordinator.navigate(to: .open(currentLanguage: .default))
        let action = try XCTUnwrap(navigationController.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is SelectLanguageView)
    }

    /// `makeSendCoordinator()` builds the send coordinator.
    @MainActor
    func test_makeSendCoordinator() {
        let navigationController = UINavigationController()
        let coordinator = subject.makeSendCoordinator(
            stackNavigator: navigationController,
        )
        coordinator.start()
        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertTrue(navigationController.viewControllers[0] is UIHostingController<SendListView>)
    }

    /// `makeSendItemCoordinator()` builds the send item coordinator.
    @MainActor
    func test_makeSendItemCoordinator() {
        let delegate = MockSendItemDelegate()
        let navigationController = UINavigationController()
        let coordinator = subject.makeSendItemCoordinator(
            delegate: delegate,
            stackNavigator: navigationController,
        )
        coordinator.start()
        XCTAssertEqual(navigationController.viewControllers.count, 0)
    }

    /// `makeSettingsCoordinator()` builds the settings coordinator.
    @MainActor
    func test_makeSettingsCoordinator() {
        let navigationController = UINavigationController()
        let coordinator = subject.makeSettingsCoordinator(
            delegate: MockSettingsCoordinatorDelegate(),
            stackNavigator: navigationController,
        )
        coordinator.start()
        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertTrue(navigationController.viewControllers[0] is UIHostingController<SettingsView>)
    }

    /// `makeTabCoordinator` builds the tab coordinator.
    @MainActor
    func test_makeTabCoordinator() {
        let errorReporter = MockErrorReporter()
        let tabBarController = BitwardenTabBarController()
        let settingsDelegate = MockSettingsCoordinatorDelegate()
        let vaultDelegate = MockVaultCoordinatorDelegate()
        let vaultRepository = MockVaultRepository()
        let coordinator = subject.makeTabCoordinator(
            errorReporter: errorReporter,
            rootNavigator: rootViewController,
            settingsDelegate: settingsDelegate,
            tabNavigator: tabBarController,
            vaultDelegate: vaultDelegate,
            vaultRepository: vaultRepository,
        )
        coordinator.start()
        XCTAssertNotNil(rootViewController.childViewController)
        XCTAssertTrue(rootViewController.childViewController === tabBarController)
    }

    /// `makeVaultCoordinator()` builds the vault coordinator.
    @MainActor
    func test_makeVaultCoordinator() {
        let navigationController = UINavigationController()
        let coordinator = subject.makeVaultCoordinator(
            delegate: MockVaultCoordinatorDelegate(),
            stackNavigator: navigationController,
        )
        coordinator.navigate(to: .list)
        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertTrue(navigationController.viewControllers[0] is UIHostingController<VaultListView>)
    }
}
