import AVFoundation
import SwiftUI
import XCTest

@testable import BitwardenShared

// MARK: - VaultItemCooridnatorTests

class VaultItemCoordinatorTests: BitwardenTestCase {
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
    func test_navigateTo_addItem_withoutGroup() throws {
        subject.navigate(to: .addItem())

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)

        let view = try XCTUnwrap(action.view as? AddEditItemView)
        XCTAssertEqual(view.store.state.type, .login)
    }

    /// `navigate(to:)` with `.addItem` with a group pushes the add item view onto the stack navigator.
    func test_navigateTo_addItem_withGroup() throws {
        subject.navigate(to: .addItem(group: .card))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is AddEditItemView)

        let view = try XCTUnwrap(action.view as? AddEditItemView)
        XCTAssertEqual(view.store.state.type, .card)
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

    /// `navigate(to:)` with `.editItem()` with a malformed cipher fails to trigger the show edit flow.
    func test_navigateTo_editItem_newCipher() throws {
        subject.navigate(to: .editItem(cipher: .fixture()), context: nil)

        XCTAssertNil(stackNavigator.actions.last)
    }

    /// `navigate(to:)` with `.editItem()` with an existing cipher triggers the show edit flow.
    func test_navigateTo_editItem_existingCipher() throws {
        subject.navigate(to: .editItem(cipher: .loginFixture()), context: nil)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is NavigationView<AddEditItemView>)
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

    /// `navigate(to:)` with `.setupTotpCamera` with context without conformance fails to present.
    func test_navigateTo_setupTotpCamera_noConformance() throws {
        cameraService.startResult = .success(AVCaptureSession())
        cameraService.cameraAuthorizationStatus = .authorized
        subject.navigate(to: .setupTotpCamera, context: MockProcessor<Any, Any, Any>(state: ()))
        XCTAssertTrue(stackNavigator.actions.isEmpty)
    }

    /// `navigate(to:)` with `.setupTotpCamera` without context fails to present.
    func test_navigateTo_setupTotpCamera_noContext() throws {
        cameraService.startResult = .success(AVCaptureSession())
        cameraService.cameraAuthorizationStatus = .authorized
        subject.navigate(to: .setupTotpCamera, context: nil)
        XCTAssertTrue(stackNavigator.actions.isEmpty)
    }

    /// `navigate(to:)` with `.setupTotpCamera` presents the camera totp setup screen.
    func test_navigateTo_setupTotpCamera_success() throws {
        let mockContext = MockScanDelegateProcessor(state: ())
        cameraService.startResult = .success(AVCaptureSession())
        cameraService.cameraAuthorizationStatus = .authorized
        let task = Task {
            subject.navigate(to: .setupTotpCamera, context: mockContext)
        }

        waitFor(!stackNavigator.actions.isEmpty)
        task.cancel()

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        let view = action.view as? (any View)
        XCTAssertNotNil(try? view?.inspect().find(ScanCodeView.self))
    }

    /// `navigate(to:)` with `.setupTotpCamera` fails without an AVCaptureSession.
    ///     The user is redirected to the manual setup.
    func test_navigateTo_setupTotpCamera_fail() throws {
        let mockContext = MockScanDelegateProcessor(state: ())
        cameraService.startResult = .failure(CameraServiceError.unableToStartCaptureSession)
        let task = Task {
            subject.navigate(to: .setupTotpCamera, context: mockContext)
        }

        waitFor(!stackNavigator.actions.isEmpty)
        task.cancel()
        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is NavigationView<Text>)
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
        subject.navigate(to: .setupTotpManual, context: mockContext)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is NavigationView<Text>)
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

/// A MockProcessor with ScanCodeCoordinatorDelegate conformance.
///
class MockScanDelegateProcessor: MockProcessor<Any, Any, Any>, ScanCodeCoordinatorDelegate {
    /// A property to capture a `didCompleteScan` call value.
    var capturedScan: String?

    /// A flag to capture a `didCancel` call.
    var didCancel: Bool = false

    func didCompleteScan(with value: String) {
        capturedScan = value
    }

    func didCancelScan() {
        didCancel = true
    }
}
