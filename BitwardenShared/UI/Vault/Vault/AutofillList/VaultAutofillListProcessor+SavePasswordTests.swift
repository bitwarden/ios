// swiftlint:disable:this file_name

import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - VaultAutofillListProcessorSavePasswordTests

/// Tests for `VaultAutofillListProcessor` when it's used to choose which login to update in the
/// AutoFill extension's save-password-credential flow.
@MainActor
struct VaultAutofillListProcessorSavePasswordTests {
    // MARK: Properties

    let coordinator: MockCoordinator<VaultRoute, AuthAction>
    let errorReporter: MockErrorReporter
    let searchProcessorMediator: MockSearchProcessorMediator
    let vaultRepository: MockVaultRepository

    // MARK: Setup

    init() {
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        searchProcessorMediator = MockSearchProcessorMediator()
        vaultRepository = MockVaultRepository()
    }

    // MARK: Tests

    /// `perform(_:)` with `.streamAutofillItems` only shows the logins the user can choose from to
    /// update, and drops sections left empty.
    @Test
    @available(iOS 17.0, *)
    func perform_streamAutofillItems_onlyLoginsToUpdate() async throws {
        let (_, subject) = makeSubject()
        let candidates: [CipherListView] = [.fixture(id: "1"), .fixture(id: "3")]
        vaultRepository.ciphersAutofillSubject.value = VaultListData(sections: [
            VaultListSection(
                id: "passwords",
                items: [.fixture(id: "1"), .fixture(id: "2"), .fixture(id: "3")]
                    .compactMap { VaultListItem(cipherListView: $0) },
                name: "",
            ),
            VaultListSection(
                id: "other",
                items: [.fixture(id: "4")].compactMap { VaultListItem(cipherListView: $0) },
                name: "",
            ),
        ])

        let task = Task {
            await subject.perform(.streamAutofillItems)
        }
        defer { task.cancel() }
        try await waitForAsync { subject.state.loadingState.data != nil }

        #expect(subject.state.loadingState.data == [
            VaultListSection(
                id: "passwords",
                items: candidates.compactMap { VaultListItem(cipherListView: $0) },
                name: "",
            ),
        ])
    }

    /// Search results only include logins the user can edit, since search covers the whole vault.
    @Test
    @available(iOS 17.0, *)
    func searchResults_onlyEditableLogins() async throws {
        let (_, subject) = makeSubject()
        subject.receive(.searchStateChanged(isSearching: true))
        let editable = CipherListView.fixture(id: "5", edit: true)
        let searchResults = VaultListData(sections: [
            VaultListSection(
                id: "search",
                items: [
                    editable,
                    .fixture(id: "6", edit: false),
                    .fixture(id: "7", type: .secureNote, edit: true),
                ].compactMap { VaultListItem(cipherListView: $0) },
                name: "",
            ),
        ])

        await searchProcessorMediator.startSearchingReceivedArguments?.onNewSearchResults(searchResults)

        #expect(subject.state.ciphersForSearch == [
            VaultListSection(
                id: "search",
                items: [editable].compactMap { VaultListItem(cipherListView: $0) },
                name: "",
            ),
        ])
        #expect(!subject.state.showNoResults)
    }

    /// `perform(_:)` with `.vaultItemTapped` updates the chosen login with the password from the
    /// save-password request.
    @Test
    @available(iOS 17.0, *)
    func perform_vaultItemTapped_updatesLogin() async throws {
        let (appExtensionDelegate, subject) = makeSubject()
        let cipherView = CipherView.loginFixture(id: "1")
        vaultRepository.fetchCipherResult = .success(cipherView)
        let item = try #require(VaultListItem(cipherListView: .fixture(id: "1")))

        await subject.perform(.vaultItemTapped(item))

        #expect(vaultRepository.fetchCipherId == "1")
        #expect(appExtensionDelegate.updateLoginForSavePasswordRequestCipher == cipherView)
        #expect(coordinator.alertShown.isEmpty)
    }

    /// `perform(_:)` with `.vaultItemTapped` shows an error alert and logs the error when updating
    /// the chosen login fails.
    @Test
    @available(iOS 17.0, *)
    func perform_vaultItemTapped_updateError() async throws {
        let (appExtensionDelegate, subject) = makeSubject()
        vaultRepository.fetchCipherResult = .success(.loginFixture(id: "1"))
        appExtensionDelegate.updateLoginForSavePasswordRequestError = BitwardenTestError.example
        let item = try #require(VaultListItem(cipherListView: .fixture(id: "1")))

        await subject.perform(.vaultItemTapped(item))

        #expect(coordinator.alertShown == [.defaultAlert(title: Localizations.anErrorHasOccurred)])
        #expect(errorReporter.errors as? [BitwardenTestError] == [.example])
    }

    /// `perform(_:)` with `.vaultItemTapped` shows an error alert when the chosen login can't be
    /// found.
    @Test
    @available(iOS 17.0, *)
    func perform_vaultItemTapped_loginNotFound() async throws {
        let (appExtensionDelegate, subject) = makeSubject()
        vaultRepository.fetchCipherResult = .success(nil)
        let item = try #require(VaultListItem(cipherListView: .fixture(id: "1")))

        await subject.perform(.vaultItemTapped(item))

        #expect(coordinator.alertShown == [.defaultAlert(title: Localizations.anErrorHasOccurred)])
        #expect(appExtensionDelegate.updateLoginForSavePasswordRequestCipher == nil)
    }

    /// `receive(_:)` with `.addTapped` shows the add item screen prefilled with the credential from
    /// the save-password request, to save it as a new login.
    @Test
    @available(iOS 17.0, *)
    func receive_addTapped_savesAsNewLogin() {
        let (appExtensionDelegate, subject) = makeSubject()
        let saveAsNewLoginRoute = VaultRoute.addItem(
            group: .login,
            newCipherOptions: NewCipherOptions(password: "pass", uri: "https://example.com", username: "user"),
            type: .login,
        )
        appExtensionDelegate.authCompletionRoute = .vault(saveAsNewLoginRoute)

        subject.receive(.addTapped(fromFAB: true))

        #expect(coordinator.routes == [saveAsNewLoginRoute])
    }

    // MARK: Private

    /// Creates the subject in the save-password-credential flow, limited to the logins with IDs
    /// "1" and "3".
    ///
    /// - Returns: The extension delegate and the subject.
    ///
    @available(iOS 17.0, *)
    private func makeSubject() -> (MockCredentialProviderExtensionDelegate, VaultAutofillListProcessor) {
        let appExtensionDelegate = MockCredentialProviderExtensionDelegate()
        appExtensionDelegate.extensionMode = .savePasswordCredential(
            MockSavePasswordRequestProxy(),
            userInteraction: true,
        )
        let searchProcessorMediatorFactory = MockSearchProcessorMediatorFactory()
        searchProcessorMediatorFactory.makeReturnValue = searchProcessorMediator
        let subject = VaultAutofillListProcessor(
            appExtensionDelegate: appExtensionDelegate,
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter,
                searchProcessorMediatorFactory: searchProcessorMediatorFactory,
                vaultRepository: vaultRepository,
            ),
            state: VaultAutofillListState(savePasswordLoginIds: ["1", "3"]),
        )
        return (appExtensionDelegate, subject)
    }
}
