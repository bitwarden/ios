// swiftlint:disable:this file_name

import AuthenticationServices
import BitwardenKitMocks
import BitwardenSdk
import Networking
import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - AddItemProcessorTests

@available(iOS 17.0, *)
class AddEditItemProcessorFido2Tests: BitwardenTestCase {
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var appExtensionDelegate: MockCredentialProviderExtensionDelegate!
    var cameraService: MockCameraService!
    var client: MockHTTPClient!
    var coordinator: MockCoordinator<VaultItemRoute, VaultItemEvent>!
    var delegate: MockCipherItemOperationDelegate!
    var errorReporter: MockErrorReporter!
    var fido2UserInterfaceHelper: MockFido2UserInterfaceHelper!
    var pasteboardService: MockPasteboardService!
    var policyService: MockPolicyService!
    var reviewPromptService: MockReviewPromptService!
    var stateService: MockStateService!
    var totpService: MockTOTPService!
    var subject: AddEditItemProcessor!
    var vaultItemActionHelper: MockVaultItemActionHelper!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        authRepository = MockAuthRepository()
        appExtensionDelegate = MockCredentialProviderExtensionDelegate()
        cameraService = MockCameraService()
        client = MockHTTPClient()
        coordinator = MockCoordinator<VaultItemRoute, VaultItemEvent>()
        delegate = MockCipherItemOperationDelegate()
        errorReporter = MockErrorReporter()
        fido2UserInterfaceHelper = MockFido2UserInterfaceHelper()
        pasteboardService = MockPasteboardService()
        policyService = MockPolicyService()
        reviewPromptService = MockReviewPromptService()
        stateService = MockStateService()
        totpService = MockTOTPService()
        vaultItemActionHelper = MockVaultItemActionHelper()
        vaultRepository = MockVaultRepository()

        subject = AddEditItemProcessor(
            appExtensionDelegate: appExtensionDelegate,
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                cameraService: cameraService,
                errorReporter: errorReporter,
                fido2UserInterfaceHelper: fido2UserInterfaceHelper,
                httpClient: client,
                pasteboardService: pasteboardService,
                policyService: policyService,
                reviewPromptService: reviewPromptService,
                stateService: stateService,
                totpService: totpService,
                vaultRepository: vaultRepository,
            ),
            state: CipherItemState(
                customFields: [
                    CustomFieldState(
                        name: "fieldName1",
                        type: .hidden,
                        value: "old",
                    ),
                ],
                hasPremium: true,
            ),
            vaultItemActionHelper: vaultItemActionHelper,
        )
    }

    override func tearDown() {
        super.tearDown()
        authRepository = nil
        appExtensionDelegate = nil
        cameraService = nil
        client = nil
        coordinator = nil
        errorReporter = nil
        pasteboardService = nil
        reviewPromptService = nil
        stateService = nil
        subject = nil
        totpService = nil
        vaultItemActionHelper = nil
        vaultRepository = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.savePressed` in the app extension completes picks the credential
    /// for creation in a Fido2 context where there is a Fido2 creation request.
    @MainActor
    func test_perform_savePressed_fido2Succeeds() async {
        subject.state.name = "name"
        appExtensionDelegate.extensionMode = .registerFido2Credential(ASPasskeyCredentialRequest.fixture())
        fido2UserInterfaceHelper.fido2CreationOptions = CheckUserOptions(
            requirePresence: true,
            requireVerification: .preferred,
        )
        fido2UserInterfaceHelper.checkUserResult = .success(CheckUserResult(userPresent: true, userVerified: true))

        await subject.perform(.savePressed)

        fido2UserInterfaceHelper.pickedCredentialForCreationMocker.assertUnwrapping { result in
            guard case let .success(pickedResult) = result,
                  pickedResult.cipher.cipher.id == subject.state.cipher.id,
                  pickedResult.checkUserResult.userPresent,
                  pickedResult.checkUserResult.userVerified else {
                return false
            }
            return true
        }

        XCTAssertTrue(vaultRepository.addCipherCiphers.isEmpty)
    }

    /// `perform(_:)` with `.savePressed` in the app extension completes pick the credential
    /// for creation in a Fido2 context where there is a Fido2 creation request and check user fails.
    @MainActor
    func test_perform_savePressed_fido2FailsUV() async {
        subject.state.name = "name"
        appExtensionDelegate.extensionMode = .registerFido2Credential(ASPasskeyCredentialRequest.fixture())
        fido2UserInterfaceHelper.fido2CreationOptions = CheckUserOptions(
            requirePresence: true,
            requireVerification: .preferred,
        )
        fido2UserInterfaceHelper.checkUserResult = .success(CheckUserResult(userPresent: true, userVerified: false))

        await subject.perform(.savePressed)

        fido2UserInterfaceHelper.pickedCredentialForCreationMocker.assertUnwrapping { result in
            guard case let .success(pickedResult) = result,
                  pickedResult.cipher.cipher.id == subject.state.cipher.id,
                  pickedResult.checkUserResult.userPresent,
                  !pickedResult.checkUserResult.userVerified else {
                return false
            }
            return true
        }

        XCTAssertTrue(vaultRepository.addCipherCiphers.isEmpty)
    }

    /// `perform(_:)` with `.savePressed` in the app extension completes pick the credential
    /// for creation in a Fido2 context where there is a Fido2 creation request and no fido2 creation options
    /// to perform check user.
    @MainActor
    func test_perform_savePressed_fido2NoCreationOptions() async {
        subject.state.name = "name"
        appExtensionDelegate.extensionMode = .registerFido2Credential(ASPasskeyCredentialRequest.fixture())

        await subject.perform(.savePressed)

        fido2UserInterfaceHelper.pickedCredentialForCreationMocker.assertUnwrapping { result in
            guard case let .success(pickedResult) = result,
                  pickedResult.cipher.cipher.id == subject.state.cipher.id,
                  pickedResult.checkUserResult.userPresent,
                  !pickedResult.checkUserResult.userVerified else {
                return false
            }
            return true
        }

        XCTAssertTrue(vaultRepository.addCipherCiphers.isEmpty)
    }

    /// `perform(_:)` with `.savePressed` in the app extension doesn't completes pick the credential
    /// for creation in a Fido2 context where there is a Fido2 creation request and check user is cancelled.
    @MainActor
    func test_perform_savePressed_fido2Cancelled() async {
        subject.state.name = "name"
        appExtensionDelegate.extensionMode = .registerFido2Credential(ASPasskeyCredentialRequest.fixture())
        fido2UserInterfaceHelper.fido2CreationOptions = CheckUserOptions(
            requirePresence: true,
            requireVerification: .required,
        )
        fido2UserInterfaceHelper.checkUserResult = .failure(UserVerificationError.cancelled)

        await subject.perform(.savePressed)

        XCTAssertFalse(fido2UserInterfaceHelper.pickedCredentialForCreationMocker.called)
        XCTAssertTrue(vaultRepository.addCipherCiphers.isEmpty)
    }

    /// `perform(_:)` with `.savePressed` in the app extension doesn't completes pick the credential
    /// for creation in a Fido2 context where there is a Fido2 creation request and check user throws..
    @MainActor
    func test_perform_savePressed_fido2Throws() async {
        subject.state.name = "name"
        appExtensionDelegate.extensionMode = .registerFido2Credential(ASPasskeyCredentialRequest.fixture())
        fido2UserInterfaceHelper.fido2CreationOptions = CheckUserOptions(
            requirePresence: true,
            requireVerification: .required,
        )
        fido2UserInterfaceHelper.checkUserResult = .failure(BitwardenTestError.example)

        await subject.perform(.savePressed)

        XCTAssertFalse(fido2UserInterfaceHelper.pickedCredentialForCreationMocker.called)
        XCTAssertTrue(vaultRepository.addCipherCiphers.isEmpty)
        XCTAssertEqual(errorReporter.errors.first as? BitwardenTestError, .example)
    }

    /// `perform(_:)` with `.savePressed` in the save-password-credential extension flow adds
    /// the cipher and completes the save password request without navigating away.
    @MainActor
    func test_perform_savePressed_savePasswordCredential() async {
        subject.state.name = "example.com"
        subject.state.loginState.username = "user@example.com"
        subject.state.loginState.password = "s3cr3t"
        appExtensionDelegate.extensionMode = .savePasswordCredential(
            MockSavePasswordRequestProxy(),
            userInteraction: true,
        )

        await subject.perform(.savePressed)

        XCTAssertFalse(vaultRepository.addCipherCiphers.isEmpty)
        XCTAssertTrue(appExtensionDelegate.completeSavePasswordRequestCalled)
        XCTAssertTrue(coordinator.routes.isEmpty)
        XCTAssertTrue(reviewPromptService.userActions.isEmpty)
    }

    /// `perform(_:)` with `.savePressed` in the save-password-credential flow shows an error alert
    /// and stays on screen when the vault save fails.
    @MainActor
    func test_perform_savePressed_savePasswordCredential_saveError() async {
        subject.state.name = "example.com"
        appExtensionDelegate.extensionMode = .savePasswordCredential(
            MockSavePasswordRequestProxy(),
            userInteraction: true,
        )
        vaultRepository.addCipherResult = .failure(BitwardenTestError.example)

        await subject.perform(.savePressed)

        XCTAssertFalse(appExtensionDelegate.completeSavePasswordRequestCalled)
        XCTAssertEqual(coordinator.errorAlertsShown.last as? BitwardenTestError, .example)
        XCTAssertTrue(coordinator.routes.isEmpty)
    }

    /// `receive(_:)` with `.dismissPressed` in the save-password-credential extension flow cancels
    /// the extension instead of dismissing only the coordinator, which would leave a blank screen.
    @MainActor
    func test_receive_dismissPressed_savePasswordExtensionFlow_cancelsExtension() {
        appExtensionDelegate.extensionMode = .savePasswordCredential(
            MockSavePasswordRequestProxy(),
            userInteraction: true,
        )

        subject.receive(.dismissPressed)

        XCTAssertTrue(appExtensionDelegate.didCancelCalled)
        XCTAssertTrue(coordinator.routes.isEmpty)
    }
}

// MARK: - MockSavePasswordRequestProxy

private class MockSavePasswordRequestProxy: SavePasswordRequestProxy {}
