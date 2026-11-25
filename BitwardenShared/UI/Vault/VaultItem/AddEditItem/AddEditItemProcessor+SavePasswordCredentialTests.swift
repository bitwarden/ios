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
    /// An existing login with the password "old".
    let existingLogin = CipherView.loginFixture(
        id: "existing-cipher-id",
        login: .fixture(password: "old", username: "user"),
    )
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

    /// `perform(_:)` with `.savePressed` in the save-password-credential extension flow doesn't
    /// complete the save password request until the added login's identities are in the identity
    /// store, so the extension isn't torn down before the identity store is updated.
    @Test
    @available(iOS 17.0, *)
    func perform_savePressed_savePasswordCredential_waitsForUpsert() async throws {
        let (appExtensionDelegate, subject) = makeSubject()

        subject.state.name = "example.com"
        subject.state.loginState.username = "user@example.com"
        subject.state.loginState.password = "s3cr3t"
        appExtensionDelegate.extensionMode = .savePasswordCredential(
            MockSavePasswordRequestProxy(),
            userInteraction: true,
        )
        autofillCredentialService.upsertCredentialsInStoreSuspends = true
        vaultRepository.addCipherResult = .success(.fixture(id: "new-cipher-id"))

        let task = Task { await subject.perform(.savePressed) }

        try await waitForAsync { autofillCredentialService.upsertCredentialsInStoreContinuation != nil }
        #expect(!appExtensionDelegate.completeSavePasswordRequestCalled)

        autofillCredentialService.resumeUpsertCredentialsInStore()
        await task.value

        #expect(appExtensionDelegate.completeSavePasswordRequestCalled)
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

    /// The processor fills in the password from the save-password request when editing an existing
    /// login in the save-password-credential flow, as if the user entered it.
    @Test
    @available(iOS 17.0, *)
    func init_existingLogin_fillsRequestPassword() throws {
        let (_, subject) = try makeSubject(
            extensionMode: .savePasswordCredential(
                MockSavePasswordRequestProxy(password: "new"),
                userInteraction: true,
            ),
            state: #require(CipherItemState(existing: existingLogin, hasPremium: true)),
        )

        #expect(subject.state.loginState.password == "new")
        #expect(subject.state.cipher == existingLogin)
    }

    /// The processor doesn't change the password when editing an existing login outside the
    /// save-password-credential flow.
    @Test
    @available(iOS 17.0, *)
    func init_existingLogin_notSavePasswordCredential() throws {
        let (_, subject) = try makeSubject(
            extensionMode: .configureAutofill,
            state: #require(CipherItemState(existing: existingLogin, hasPremium: true)),
        )

        #expect(subject.state.loginState.password == "old")
    }

    /// `perform(_:)` with `.streamCipherDetails` keeps the password from the save-password request
    /// when the login is refreshed from the vault, since it isn't saved yet.
    @Test
    @available(iOS 17.0, *)
    func perform_streamCipherDetails_savePasswordCredential_keepsPassword() async throws {
        let (appExtensionDelegate, subject) = try makeSubject(
            extensionMode: .savePasswordCredential(
                MockSavePasswordRequestProxy(password: "new"),
                userInteraction: true,
            ),
            state: #require(CipherItemState(existing: existingLogin, hasPremium: true)),
        )
        let task = Task {
            await subject.perform(.streamCipherDetails)
        }
        defer { task.cancel() }

        vaultRepository.cipherDetailsSubject.send(.loginFixture(
            id: "existing-cipher-id",
            login: .fixture(password: "old", username: "user"),
            name: "Updated name",
        ))
        try await waitForAsync { subject.state.name == "Updated name" }

        #expect(subject.state.loginState.password == "new")
        #expect(appExtensionDelegate.isSavingPasswordCredential)
    }

    /// `perform(_:)` with `.savePressed` when editing an existing login in the
    /// save-password-credential flow updates the login with the password from the request, keeps the
    /// previous password in its history, adds its identities to the identity store, and completes the
    /// save password request without navigating away.
    @Test
    @available(iOS 17.0, *)
    func perform_savePressed_savePasswordCredential_existingLogin() async throws {
        let (appExtensionDelegate, subject) = try makeSubject(
            extensionMode: .savePasswordCredential(
                MockSavePasswordRequestProxy(password: "new"),
                userInteraction: true,
            ),
            state: #require(CipherItemState(existing: existingLogin, hasPremium: true)),
        )

        await subject.perform(.savePressed)

        let updatedLogin = try #require(vaultRepository.updateCipherCiphers.first)
        #expect(vaultRepository.updateCipherCiphers.count == 1)
        #expect(updatedLogin.id == "existing-cipher-id")
        #expect(updatedLogin.login?.password == "new")
        #expect(updatedLogin.passwordHistory?.first?.password == "old")
        #expect(autofillCredentialService.upsertCredentialsInStoreCipherIds == ["existing-cipher-id"])
        #expect(appExtensionDelegate.completeSavePasswordRequestCalled)
        #expect(coordinator.routes.isEmpty)
        #expect(!delegate.itemUpdatedCalled)
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
    /// - Parameters:
    ///   - extensionMode: The mode the extension is running in.
    ///   - state: The initial state of the processor.
    /// - Returns: The extension delegate and the processor under test.
    ///
    @available(iOS 17.0, *)
    private func makeSubject(
        extensionMode: CredentialProviderMode = .configureAutofill,
        state: AddEditItemState = CipherItemState(hasPremium: true),
    ) -> (MockCredentialProviderExtensionDelegate, AddEditItemProcessor) {
        let appExtensionDelegate = MockCredentialProviderExtensionDelegate()
        appExtensionDelegate.extensionMode = extensionMode
        let subject = AddEditItemProcessor(
            appExtensionDelegate: appExtensionDelegate,
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            services: ServiceContainer.withMocks(
                autofillCredentialService: autofillCredentialService,
                reviewPromptService: reviewPromptService,
                vaultRepository: vaultRepository,
            ),
            state: state,
            vaultItemActionHelper: MockVaultItemActionHelper(),
        )
        return (appExtensionDelegate, subject)
    }
}
