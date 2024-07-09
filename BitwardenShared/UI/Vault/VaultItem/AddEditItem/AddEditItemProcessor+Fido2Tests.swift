// swiftlint:disable:this file_name

import BitwardenSdk
import Networking
import XCTest

@testable import BitwardenShared

// MARK: - AddItemProcessorTests

@available(iOS 17.0, *)
class AddEditItemProcessorFido2Tests: BitwardenTestCase {
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var appExtensionDelegate: MockFido2AppExtensionDelegate!
    var cameraService: MockCameraService!
    var client: MockHTTPClient!
    var coordinator: MockCoordinator<VaultItemRoute, VaultItemEvent>!
    var delegate: MockCipherItemOperationDelegate!
    var errorReporter: MockErrorReporter!
    var fido2UserInterfaceHelper: MockFido2UserInterfaceHelper!
    var pasteboardService: MockPasteboardService!
    var policyService: MockPolicyService!
    var stateService: MockStateService!
    var totpService: MockTOTPService!
    var subject: AddEditItemProcessor!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        authRepository = MockAuthRepository()
        appExtensionDelegate = MockFido2AppExtensionDelegate()
        cameraService = MockCameraService()
        client = MockHTTPClient()
        coordinator = MockCoordinator<VaultItemRoute, VaultItemEvent>()
        delegate = MockCipherItemOperationDelegate()
        errorReporter = MockErrorReporter()
        fido2UserInterfaceHelper = MockFido2UserInterfaceHelper()
        pasteboardService = MockPasteboardService()
        policyService = MockPolicyService()
        stateService = MockStateService()
        totpService = MockTOTPService()
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
                stateService: stateService,
                totpService: totpService,
                vaultRepository: vaultRepository
            ),
            state: CipherItemState(
                customFields: [
                    CustomFieldState(
                        name: "fieldName1",
                        type: .hidden,
                        value: "old"
                    ),
                ],
                hasPremium: true
            )
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
        stateService = nil
        subject = nil
        totpService = nil
        vaultRepository = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.savePressed` in the app extension completes picks the credential
    /// for creation in a Fido2 context where there is a Fido2 creation request.
    func test_perform_savePressed_fido2AppExtension() async {
        subject.state.name = "name"
        appExtensionDelegate.getRequestForFido2CreationResult = .fixture()

        await subject.perform(.savePressed)

        fido2UserInterfaceHelper.pickedCredentialForCreationMocker.assertUnwrapping { result in
            guard case let .success(pickedResult) = result,
                  pickedResult.cipher.cipher.id == subject.state.cipher.id else {
                return false
            }
            return true
        }

        XCTAssertTrue(vaultRepository.addCipherCiphers.isEmpty)
    }
}
