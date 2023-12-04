import SwiftUI
import XCTest

@testable import BitwardenShared

// MARK: - VaultItemCooridnatorTests

class VaultItemCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var module: MockAppModule!
    var stackNavigator: MockStackNavigator!
    var subject: VaultItemCoordinator!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        module = MockAppModule()
        stackNavigator = MockStackNavigator()
        vaultRepository = MockVaultRepository()
        subject = VaultItemCoordinator(
            module: module,
            services: ServiceContainer.withMocks(
                vaultRepository: vaultRepository
            ),
            stackNavigator: stackNavigator
        )
    }

    override func tearDown() {
        super.tearDown()
        module = nil
        stackNavigator = nil
        subject = nil
        vaultRepository = nil
    }

    // MARK: Tests

    /// `navigate(to:)` with `.addItem` without a group pushes the add item view onto the stack navigator.
    func test_navigateTo_addItem_withoutGroup() throws {
        subject.navigate(to: .addItem())

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)

        let view = try XCTUnwrap(action.view as? AddEditItemView)
        XCTAssertEqual(view.store.state.properties.type, .login)
    }

    /// `navigate(to:)` with `.addItem` with a group pushes the add item view onto the stack navigator.
    func test_navigateTo_addItem_withGroup() throws {
        subject.navigate(to: .addItem(group: .card))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is AddEditItemView)

        let view = try XCTUnwrap(action.view as? AddEditItemView)
        XCTAssertEqual(view.store.state.properties.type, .card)
    }

    /// `navigate(to:)` with `.alert` presents the provided alert on the stack navigator.
    func test_navigate_alert() {
        let alert = BitwardenShared.Alert(
            title: "title",
            message: "message",
            preferredStyle: .alert,
            alertActions: [
                AlertAction(
                    title: "alert title",
                    style: .cancel
                ),
            ]
        )

        subject.navigate(to: .alert(alert))
        XCTAssertEqual(stackNavigator.alerts.last, alert)
    }

    /// `navigate(to:)` with `.generator`, `.password`, and a delegate presents the generator
    /// screen.
    func test_navigateTo_generator_withPassword_withDelegate() throws {
        let delegate = MockGeneratorCoordinatorDelegate()
        subject.navigate(to: .generator(.password), context: delegate)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is UINavigationController)

        XCTAssertTrue(module.generatorCoordinator.isStarted)
        XCTAssertEqual(module.generatorCoordinator.routes.last, .generator(staticType: .password))
    }

    /// `navigate(to:)` with `.dismiss` dismisses the top most view presented by the stack
    /// navigator.
    func test_navigate_dismiss() throws {
        subject.navigate(to: .dismiss)
        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .dismissed)
    }

    /// `navigate(to:)` with `.generator`, `.password`, and without a delegate does not present the
    /// generator screen.
    func test_navigateTo_generator_withPassword_withoutDelegate() throws {
        subject.navigate(to: .generator(.password), context: nil)

        XCTAssertNil(stackNavigator.actions.last)
    }

    /// `navigate(to:)` with `.generator`, `.username`, and a delegate presents the generator
    /// screen.
    func test_navigateTo_generator_withUsername_withDelegate() throws {
        let delegate = MockGeneratorCoordinatorDelegate()
        subject.navigate(to: .generator(.username), context: delegate)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is UINavigationController)

        XCTAssertTrue(module.generatorCoordinator.isStarted)
        XCTAssertEqual(module.generatorCoordinator.routes.last, .generator(staticType: .username))
    }

    /// `navigate(to:)` with `.generator`, `.username`, `emailWebsite` and a delegate presents the
    /// generator screen.
    func test_navigateTo_generator_withUsername_withDelegate_withEmailWebsite() throws {
        let delegate = MockGeneratorCoordinatorDelegate()
        subject.navigate(to: .generator(.username, emailWebsite: "bitwarden.com"), context: delegate)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is UINavigationController)

        XCTAssertTrue(module.generatorCoordinator.isStarted)
        XCTAssertEqual(
            module.generatorCoordinator.routes.last,
            .generator(staticType: .username, emailWebsite: "bitwarden.com")
        )
    }

    /// `navigate(to:)` with `.generator`, `.username`, and without a delegate does not present the
    /// generator screen.
    func test_navigateTo_generator_withUsername_withoutDelegate() throws {
        subject.navigate(to: .generator(.username), context: nil)

        XCTAssertNil(stackNavigator.actions.last)
    }

    /// `navigate(to:)` with `.setupTotpCamera` presents the camera totp setup screen.
    func test_navigateTo_setupTotpCamera() throws {
        subject.navigate(to: .setupTotpCamera)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is Text)
    }

    /// `navigate(to:)` with `.setupTotpManual` presents the manual totp setup screen.
    func test_navigateTo_setupTotpManual() throws {
        subject.navigate(to: .setupTotpManual)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is Text)
    }

    /// `.navigate(to:)` with `.viewItem` presents the view item screen.
    func test_navigateTo_viewItem() throws {
        subject.navigate(to: .viewItem(id: "id"))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is ViewItemView)
    }

    /// `start()` has no effect.
    func test_start() {
        subject.start()

        XCTAssertTrue(stackNavigator.actions.isEmpty)
    }
}
