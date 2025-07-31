// swiftlint:disable:this file_name

import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import TestHelpers
import XCTest

@testable import BitwardenShared

@available(iOS 18.0, *)
class VaultAutofillListProcessorAutofillModeAllTests: BitwardenTestCase {
    // MARK: Properties

    var appExtensionDelegate: MockAutofillAppExtensionDelegate!
    var authRepository: MockAuthRepository!
    var clientService: MockClientService!
    var coordinator: MockCoordinator<VaultRoute, AuthAction>!
    var errorReporter: MockErrorReporter!
    var fido2CredentialStore: MockFido2CredentialStore!
    var fido2UserInterfaceHelper: MockFido2UserInterfaceHelper!
    var stateService: MockStateService!
    var subject: VaultAutofillListProcessor!
    var textAutofillHelper: MockTextAutofillHelper!
    var textAutofillHelperFactory: MockTextAutofillHelperFactory!
    var totpExpirationManagerFactory: MockTOTPExpirationManagerFactory!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appExtensionDelegate = MockAutofillAppExtensionDelegate()
        appExtensionDelegate.extensionMode = .autofillText
        authRepository = MockAuthRepository()
        clientService = MockClientService()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        fido2CredentialStore = MockFido2CredentialStore()
        fido2UserInterfaceHelper = MockFido2UserInterfaceHelper()
        stateService = MockStateService()
        textAutofillHelper = MockTextAutofillHelper()
        textAutofillHelperFactory = MockTextAutofillHelperFactory()
        textAutofillHelperFactory.createResult = textAutofillHelper
        totpExpirationManagerFactory = MockTOTPExpirationManagerFactory()
        vaultRepository = MockVaultRepository()

        subject = VaultAutofillListProcessor(
            appExtensionDelegate: appExtensionDelegate,
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                clientService: clientService,
                errorReporter: errorReporter,
                fido2CredentialStore: fido2CredentialStore,
                fido2UserInterfaceHelper: fido2UserInterfaceHelper,
                stateService: stateService,
                textAutofillHelperFactory: textAutofillHelperFactory,
                totpExpirationManagerFactory: totpExpirationManagerFactory,
                vaultRepository: vaultRepository
            ),
            state: VaultAutofillListState()
        )
    }

    override func tearDown() {
        super.tearDown()

        appExtensionDelegate = nil
        authRepository = nil
        clientService = nil
        coordinator = nil
        errorReporter = nil
        fido2CredentialStore = nil
        fido2UserInterfaceHelper = nil
        stateService = nil
        subject = nil
        totpExpirationManagerFactory = nil
        vaultRepository = nil
    }

    // MARK: Tests

    /// `completeTextRequest(text:)` calls the app extension delegate to complete the text request.
    @MainActor
    func test_completeTextRequest() {
        subject.completeTextRequest(text: "Text to insert")
        XCTAssertEqual(appExtensionDelegate.completeTextRequestTextToInsert, "Text to insert")
    }

    /// `init(appExtensionDelegate:coordinator:services:state:)` initializes
    /// the state with totp.
    @MainActor
    func test_init() {
        XCTAssertTrue(subject.state.isAutofillingTextToInsertList)
        XCTAssertEqual(subject.state.emptyViewMessage, Localizations.noItemsToList)
    }

    /// `perform(_:)` with `.search()` performs a cipher search and updates the state with the results.
    @MainActor
    func test_perform_search() {
        let items = [
            VaultListItem(
                id: "1",
                itemType: .cipher(
                    .fixture(
                        id: "1",
                        type: .card(.init(brand: nil))
                    )
                )
            ),
            VaultListItem(
                id: "2",
                itemType: .cipher(
                    .fixture(
                        id: "2",
                        type: .identity
                    )
                )
            ),
        ]
        let expectedSection = VaultListSection(
            id: "",
            items: items,
            name: ""
        )
        vaultRepository.searchCipherAutofillSubject.value = VaultListData(sections: [expectedSection])

        let task = Task {
            await subject.perform(.search("Bit"))
        }

        waitFor(!subject.state.ciphersForSearch.isEmpty)
        task.cancel()

        XCTAssertEqual(subject.state.ciphersForSearch, [expectedSection])
        XCTAssertFalse(subject.state.showNoResults)
    }

    /// `perform(_:)` with `.search()` performs a cipher search and updates the state with the results
    /// when filtering by group.
    @MainActor
    func test_perform_searchWithGroup() {
        let items = [
            VaultListItem(
                id: "1",
                itemType: .cipher(
                    .fixture(
                        id: "1",
                        type: .card(.init(brand: nil))
                    )
                )
            ),
            VaultListItem(
                id: "2",
                itemType: .cipher(
                    .fixture(
                        id: "2",
                        type: .card(.init(brand: nil))
                    )
                )
            ),
        ]
        let expectedSection = VaultListSection(
            id: "",
            items: items,
            name: ""
        )
        vaultRepository.searchCipherAutofillSubject.value = VaultListData(sections: [expectedSection])
        subject.state.group = .card

        let task = Task {
            await subject.perform(.search("Bit"))
        }

        waitFor(!subject.state.ciphersForSearch.isEmpty)
        task.cancel()

        XCTAssertEqual(subject.state.ciphersForSearch, [expectedSection])
        XCTAssertFalse(subject.state.showNoResults)
        XCTAssertEqual(vaultRepository.searchCipherAutofillPublisherCalledWithGroup, .card)
    }

    /// `perform(_:)` with `.streamAutofillItems` streams the list of autofill ciphers.
    @MainActor
    func test_perform_streamAutofillItems() {
        let items = [
            VaultListItem(
                id: "1",
                itemType: .cipher(
                    .fixture(
                        id: "1",
                        type: .card(.init(brand: nil))
                    )
                )
            ),
            VaultListItem(
                id: "2",
                itemType: .cipher(
                    .fixture(
                        id: "2",
                        type: .identity
                    )
                )
            ),
        ]
        let expectedSection = VaultListSection(
            id: "",
            items: items,
            name: ""
        )
        vaultRepository.ciphersAutofillSubject.value = VaultListData(sections: [expectedSection])

        let task = Task {
            await subject.perform(.streamAutofillItems)
        }

        waitFor(!subject.state.vaultListSections.isEmpty)
        task.cancel()

        XCTAssertEqual(subject.state.vaultListSections, [expectedSection])
    }

    /// `perform(_:)` with `.streamAutofillItems` streams the list of autofill ciphers when filtering by group.
    @MainActor
    func test_perform_streamAutofillItemsWithGroup() {
        let items = [
            VaultListItem(
                id: "1",
                itemType: .cipher(
                    .fixture(
                        id: "1",
                        type: .card(.init(brand: nil))
                    )
                )
            ),
            VaultListItem(
                id: "2",
                itemType: .cipher(
                    .fixture(
                        id: "2",
                        type: .card(.init(brand: nil))
                    )
                )
            ),
        ]
        let expectedSection = VaultListSection(
            id: "",
            items: items,
            name: ""
        )
        vaultRepository.ciphersAutofillSubject.value = VaultListData(sections: [expectedSection])
        subject.state.group = .card

        let task = Task {
            await subject.perform(.streamAutofillItems)
        }

        waitFor(!subject.state.vaultListSections.isEmpty)
        task.cancel()

        XCTAssertEqual(subject.state.vaultListSections, [expectedSection])
        XCTAssertEqual(vaultRepository.ciphersAutofillPublisherCalledWithGroup, .card)
    }

    /// `vaultItemTapped(_:)` has the text autofill helper handle text to insert autofill for the cipher.
    @MainActor
    func test_perform_vaultItemTapped() async {
        let vaultListItem = VaultListItem(
            cipherListView: CipherListView.fixture(
                id: "1",
                login: .fixture(
                    username: "user@bitwarden.com"
                )
            )
        )!
        await subject.perform(.vaultItemTapped(vaultListItem))

        XCTAssertEqual(textAutofillHelper.handleCipherForAutofillCalledWithCipher?.id, "1")
    }

    /// `vaultItemTapped(_:)` has the text autofill helper handle text to insert autofill for the cipher but it throws.
    @MainActor
    func test_perform_vaultItemTappedThrows() async throws {
        let vaultListItem = VaultListItem(
            cipherListView: CipherListView.fixture(
                id: "1",
                login: .fixture(
                    username: "user@bitwarden.com"
                ),
                name: "Test"
            )
        )!
        textAutofillHelper.handleCipherForAutofillError = BitwardenTestError.example
        await subject.perform(.vaultItemTapped(vaultListItem))

        XCTAssertEqual(textAutofillHelper.handleCipherForAutofillCalledWithCipher?.id, "1")
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
        let alert = try XCTUnwrap(coordinator.alertShown.first)
        XCTAssertEqual(alert.title, Localizations.anErrorHasOccurred)
        XCTAssertEqual(alert.message, Localizations.failedToAutofillItem("Test"))
    }
}
