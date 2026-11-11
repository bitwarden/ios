// swiftlint:disable:this file_name

import BitwardenKitMocks
import BitwardenSdk
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - AddEditItemProcessorSavePasswordCredentialTests

/// Tests for `AddEditItemProcessor` in the AutoFill extension's save-password-credential flow.
@MainActor
struct AddEditItemProcessorSavePasswordCredentialTests {
    // MARK: Properties

    let autofillCredentialService: MockAutofillCredentialService
    let coordinator: MockCoordinator<VaultItemRoute, VaultItemEvent>
    let delegate: MockCipherItemOperationDelegate
    let reviewPromptService: MockReviewPromptService
    let vaultRepository: MockVaultRepository

    // MARK: Setup

    init() {
        autofillCredentialService = MockAutofillCredentialService()
        coordinator = MockCoordinator<VaultItemRoute, VaultItemEvent>()
        delegate = MockCipherItemOperationDelegate()
        reviewPromptService = MockReviewPromptService()
        vaultRepository = MockVaultRepository()
    }

    // MARK: Tests

    /// `perform(_:)` with `.savePressed` in the save-password-credential extension flow adds the
    /// cipher, adds its identities to the identity store, and completes the save password request
    /// without navigating away.
    @Test
    @available(iOS 17.0, *)
    func perform_savePressed_savePasswordCredential() async {
        let (appExtensionDelegate, subject) = makeSubject()

        subject.state.name = "example.com"
        subject.state.loginState.username = "user@example.com"
        subject.state.loginState.password = "s3cr3t"
        subject.state.loginState.uris = [.init(uri: "https://example.com")]
        appExtensionDelegate.extensionMode = .savePasswordCredential(
            MockSavePasswordRequestProxy(),
            userInteraction: true,
        )
        vaultRepository.addCipherResult = .success(.fixture(id: "new-cipher-id"))

        await subject.perform(.savePressed)

        #expect(vaultRepository.addCipherCiphers.count == 1)
        #expect(autofillCredentialService.upsertCredentialsInStoreCipherIds == ["new-cipher-id"])
        #expect(appExtensionDelegate.completeSavePasswordRequestCalled)
        #expect(coordinator.routes.isEmpty)
        #expect(reviewPromptService.userActions == [.addedNewItem])
    }

    /// `perform(_:)` with `.savePressed` outside the save-password-credential flow adds the cipher
    /// without updating the identity store or completing a save password request.
    @Test
    @available(iOS 17.0, *)
    func perform_savePressed_notSavePasswordCredential() async {
        let (appExtensionDelegate, subject) = makeSubject()

        subject.state.name = "example.com"
        subject.state.loginState.password = "s3cr3t"
        subject.state.loginState.uris = [.init(uri: "https://example.com")]
        appExtensionDelegate.extensionMode = .configureAutofill

        await subject.perform(.savePressed)

        #expect(vaultRepository.addCipherCiphers.count == 1)
        #expect(autofillCredentialService.upsertCredentialsInStoreCipherIds.isEmpty)
        #expect(!appExtensionDelegate.completeSavePasswordRequestCalled)
    }

    /// `perform(_:)` with `.savePressed` in the save-password-credential flow shows an error alert
    /// and stays on screen when the vault save fails.
    @Test
    @available(iOS 17.0, *)
    func perform_savePressed_savePasswordCredential_saveError() async {
        let (appExtensionDelegate, subject) = makeSubject()

        subject.state.name = "example.com"
        appExtensionDelegate.extensionMode = .savePasswordCredential(
            MockSavePasswordRequestProxy(),
            userInteraction: true,
        )
        vaultRepository.addCipherResult = .failure(BitwardenTestError.example)

        await subject.perform(.savePressed)

        #expect(autofillCredentialService.upsertCredentialsInStoreCipherIds.isEmpty)
        #expect(!appExtensionDelegate.completeSavePasswordRequestCalled)
        #expect((coordinator.errorAlertsShown.last as? BitwardenTestError) == .example)
        #expect(coordinator.routes.isEmpty)
    }

    /// `receive(_:)` with `.dismissPressed` in the save-password-credential extension flow cancels
    /// the extension instead of dismissing only the coordinator, which would leave a blank screen.
    @Test
    @available(iOS 17.0, *)
    func receive_dismissPressed_savePasswordExtensionFlow_cancelsExtension() {
        let (appExtensionDelegate, subject) = makeSubject()

        appExtensionDelegate.extensionMode = .savePasswordCredential(
            MockSavePasswordRequestProxy(),
            userInteraction: true,
        )

        subject.receive(.dismissPressed)

        #expect(appExtensionDelegate.didCancelCalled)
        #expect(coordinator.routes.isEmpty)
    }

    // MARK: Private

    /// Creates the processor under test with a credential provider extension delegate.
    ///
    /// The delegate is returned so the test keeps a strong reference to it, since the processor
    /// only holds it weakly.
    ///
    /// - Returns: The extension delegate and the processor under test.
    ///
    @available(iOS 17.0, *)
    private func makeSubject() -> (MockCredentialProviderExtensionDelegate, AddEditItemProcessor) {
        let appExtensionDelegate = MockCredentialProviderExtensionDelegate()
        let subject = AddEditItemProcessor(
            appExtensionDelegate: appExtensionDelegate,
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            services: ServiceContainer.withMocks(
                autofillCredentialService: autofillCredentialService,
                reviewPromptService: reviewPromptService,
                vaultRepository: vaultRepository,
            ),
            state: CipherItemState(hasPremium: true),
            vaultItemActionHelper: MockVaultItemActionHelper(),
        )
        return (appExtensionDelegate, subject)
    }
}
