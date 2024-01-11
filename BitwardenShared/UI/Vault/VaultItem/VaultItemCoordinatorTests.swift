import AVFoundation
import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - VaultItemCooridnatorTests

class VaultItemCoordinatorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var cameraService: MockCameraService!
    var module: MockAppModule!
    var stackNavigator: MockStackNavigator!
    var subject: VaultItemCoordinator!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        cameraService = MockCameraService()
        module = MockAppModule()
        stackNavigator = MockStackNavigator()
        vaultRepository = MockVaultRepository()
        subject = VaultItemCoordinator(
            module: module,
            services: ServiceContainer.withMocks(
                cameraService: cameraService,
                vaultRepository: vaultRepository
            ),
            stackNavigator: stackNavigator
        )
    }

    override func tearDown() {
        super.tearDown()
        cameraService = nil
        module = nil
        stackNavigator = nil
        subject = nil
        vaultRepository = nil
    }

    // MARK: Tests

    /// `navigate(to:)` with `.addItem` without a group pushes the add item view onto the stack navigator.
    func test_navigateTo_addItem_nonPremium() throws {
        vaultRepository.hasPremiumResult = .success(false)
        let task = Task {
            subject.navigate(to: .addItem())
        }
        waitFor(!stackNavigator.actions.isEmpty)
        task.cancel()

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        let view = try XCTUnwrap(action.view as? AddEditItemView)
        XCTAssertEqual(view.store.state.type, .login)
        XCTAssertFalse(view.store.state.loginState.isTOTPAvailable)
    }

    /// `navigate(to:)` with `.addItem` without a group pushes the add item view onto the stack navigator.
    func test_navigateTo_addItem_unknownPremium() throws {
        struct TestError: Error {}
        vaultRepository.hasPremiumResult = .failure(TestError())
        let task = Task {
            subject.navigate(to: .addItem())
        }
        waitFor(!stackNavigator.actions.isEmpty)
        task.cancel()

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        let view = try XCTUnwrap(action.view as? AddEditItemView)
        XCTAssertEqual(view.store.state.type, .login)
        XCTAssertFalse(view.store.state.loginState.isTOTPAvailable)
    }

    /// `navigate(to:)` with `.addItem` without a group pushes the add item view onto the stack navigator.
    func test_navigateTo_addItem_withoutGroup() throws {
        let task = Task {
            subject.navigate(to: .addItem())
        }
        waitFor(!stackNavigator.actions.isEmpty)
        task.cancel()

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)

        let view = try XCTUnwrap(action.view as? AddEditItemView)
        XCTAssertEqual(view.store.state.type, .login)
    }

    /// `navigate(to:)` with `.addItem` with a group pushes the add item view onto the stack navigator.
    func test_navigateTo_addItem_withGroup() throws {
        let task = Task {
            subject.navigate(to: .addItem(group: .card))
        }
        waitFor(!stackNavigator.actions.isEmpty)
        task.cancel()

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is AddEditItemView)

        let view = try XCTUnwrap(action.view as? AddEditItemView)
        XCTAssertEqual(view.store.state.type, .card)
    }

    /// `navigate(to:)` with `.cloneItem()`  triggers the show clone item flow.
    func test_navigateTo_cloneItem_nonPremium() throws {
        vaultRepository.hasPremiumResult = .success(false)
        subject.navigate(to: .cloneItem(cipher: .loginFixture()), context: subject)
        waitFor(!stackNavigator.actions.isEmpty)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        let view = try XCTUnwrap(action.view as? AddEditItemView)
        XCTAssertFalse(view.store.state.loginState.isTOTPAvailable)
    }

    /// `navigate(to:)` with `.editCollections()` triggers the edit collections flow.
    func test_navigateTo_editCollections() throws {
        subject.navigate(to: .editCollections(.fixture()))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        let navigationController = try XCTUnwrap(action.view as? UINavigationController)
        XCTAssertTrue(navigationController.topViewController is UIHostingController<EditCollectionsView>)
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
    func test_navigate_dismiss_noAction() throws {
        subject.navigate(to: .dismiss())
        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .dismissedWithCompletionHandler)
    }

    /// `navigate(to:)` with `.dismiss` dismisses the top most view presented by the stack
    /// navigator.
    func test_navigate_dismiss_withAction() throws {
        var didRun = false
        subject.navigate(to: .dismiss(DismissAction(action: { didRun = true })))
        let lastAction = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(lastAction.type, .dismissedWithCompletionHandler)
        XCTAssertTrue(didRun)
    }

    /// `navigate(to:)` with `.editItem()` with a malformed cipher fails to trigger the show edit flow.
    func test_navigateTo_editItem_newCipher() throws {
        subject.navigate(to: .editItem(cipher: .fixture()), context: nil)

        XCTAssertNil(stackNavigator.actions.last)
    }

    /// `navigate(to:)` with `.editItem()` with an existing cipher triggers the show edit flow.
    func test_navigateTo_editItem_existingCipher_withoutContext() throws {
        let task = Task {
            subject.navigate(to: .editItem(cipher: .loginFixture()), context: nil)
        }
        waitFor(!stackNavigator.actions.isEmpty)
        task.cancel()

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is AddEditItemView)
    }

    /// `navigate(to:)` with `.editItem()` with a non empty stack presents a new vault item coordinator.
    func test_navigateTo_editItem_presentsCoordinator() throws {
        stackNavigator.isEmpty = false

        let task = Task {
            subject.navigate(to: .editItem(cipher: .loginFixture()), context: nil)
        }
        waitFor(!stackNavigator.actions.isEmpty)
        task.cancel()

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is UINavigationController)
        XCTAssertEqual(module.vaultItemCoordinator.routes, [.editItem(cipher: .loginFixture())])
    }

    /// `navigate(to:)` with `.editItem()` with an existing cipher triggers the show edit flow.
    func test_navigateTo_editItem_existingCipher_withContext() throws {
        let task = Task {
            subject.navigate(to: .editItem(cipher: .loginFixture()), context: subject)
        }
        waitFor(!stackNavigator.actions.isEmpty)
        task.cancel()

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is AddEditItemView)
    }

    /// `navigate(to:)` with `.editItem()` with an existing cipher triggers the show edit flow.
    func test_navigateTo_editItem_existingCipher_nonPremium() throws {
        vaultRepository.hasPremiumResult = .success(false)
        let task = Task {
            subject.navigate(to: .editItem(cipher: .loginFixture()), context: subject)
        }
        waitFor(!stackNavigator.actions.isEmpty)
        task.cancel()

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        let view = try XCTUnwrap(action.view as? AddEditItemView)
        XCTAssertFalse(view.store.state.loginState.isTOTPAvailable)
    }

    /// `navigate(to:)` with `.editItem()` with an existing cipher triggers the show edit flow.
    func test_navigateTo_editItem_existingCipher_unknownPremium() throws {
        struct TestError: Error {}
        vaultRepository.hasPremiumResult = .failure(TestError())
        let task = Task {
            subject.navigate(to: .editItem(cipher: .loginFixture()), context: subject)
        }
        waitFor(!stackNavigator.actions.isEmpty)
        task.cancel()

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        let view = try XCTUnwrap(action.view as? AddEditItemView)
        XCTAssertFalse(view.store.state.loginState.isTOTPAvailable)
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

    /// `navigate(to:)` with `.moveToOrganization()` triggers the move to organization flow.
    func test_navigateTo_moveToOrganization() throws {
        subject.navigate(to: .moveToOrganization(.fixture()))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        let navigationController = try XCTUnwrap(action.view as? UINavigationController)
        XCTAssertTrue(navigationController.topViewController is UIHostingController<MoveToOrganizationView>)
    }

    /// `navigate(to:)` with `.setupTotpCamera` with context without conformance fails to present.
    func test_navigateTo_setupTotpCamera_noConformance() async throws {
        cameraService.startResult = .success(AVCaptureSession())
        cameraService.cameraAuthorizationStatus = .authorized
        await subject.navigate(asyncTo: .scanCode, context: MockProcessor<Any, Any, Any>(state: ()))
        XCTAssertTrue(stackNavigator.actions.isEmpty)
    }

    /// `navigate(to:)` with `.setupTotpCamera` without context fails to present.
    func test_navigateTo_setupTotpCamera_noContext() async throws {
        cameraService.startResult = .success(AVCaptureSession())
        cameraService.cameraAuthorizationStatus = .authorized
        await subject.navigate(asyncTo: .scanCode, context: nil)
        XCTAssertTrue(stackNavigator.actions.isEmpty)
    }

    /// `navigate(to:)` with `.setupTotpCamera` presents the camera totp setup screen.
    func test_navigateTo_setupTotpCamera_success() throws {
        let mockContext = MockScanDelegateProcessor(state: ())
        cameraService.startResult = .success(AVCaptureSession())
        cameraService.cameraAuthorizationStatus = .authorized
        cameraService.deviceHasCamera = true
        let task = Task {
            await subject.navigate(
                asyncTo: .scanCode,
                context: mockContext
            )
        }

        waitFor(!stackNavigator.actions.isEmpty)
        task.cancel()

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is UIViewController)
    }

    /// `navigate(to:)` with `.setupTotpManual` with context without conformance fails to present.
    func test_navigateTo_setupTotpManual_noConformance() throws {
        cameraService.startResult = .success(AVCaptureSession())
        cameraService.cameraAuthorizationStatus = .authorized
        subject.navigate(to: .setupTotpManual, context: MockProcessor<Any, Any, Any>(state: ()))
        XCTAssertTrue(stackNavigator.actions.isEmpty)
    }

    /// `navigate(to:)` with `.setupTotpManual` without context fails to present.
    func test_navigateTo_setupTotpManual_noContext() throws {
        cameraService.startResult = .success(AVCaptureSession())
        cameraService.cameraAuthorizationStatus = .authorized
        subject.navigate(to: .setupTotpManual, context: nil)
        XCTAssertTrue(stackNavigator.actions.isEmpty)
    }

    /// `navigate(to:)` with `.setupTotpManual` presents the manual totp setup screen.
    func test_navigateTo_setupTotpManual_success() throws {
        let mockContext = MockScanDelegateProcessor(state: ())
        let task = Task {
            subject.navigate(to: .setupTotpManual, context: mockContext)
        }

        waitFor(!stackNavigator.actions.isEmpty)
        task.cancel()

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is UIViewController)
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

/// A MockProcessor with AuthenticatorKeyCaptureDelegate conformance.
///
class MockScanDelegateProcessor: MockProcessor<Any, Any, Any>, AuthenticatorKeyCaptureDelegate {
    /// A property to capture a `AuthenticatorKeyCaptureCoordinator` call value.
    var capturedCoordinator: AnyCoordinator<AuthenticatorKeyCaptureRoute>?

    /// A property to capture a `didCompleteCapture` call value.
    var capturedScan: String?

    /// A flag to capture a `didCancel` call.
    var didCancel: Bool = false

    func didCompleteCapture(
        _ captureCoordinator: AnyCoordinator<AuthenticatorKeyCaptureRoute>,
        with value: String
    ) {
        capturedCoordinator = captureCoordinator
        capturedScan = value
    }

    func didCancelScan() {
        didCancel = true
    }
} // swiftlint:disable:this file_length
