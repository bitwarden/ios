// swiftlint:disable:this file_name

import BitwardenKitMocks
import BitwardenSdk
import TestHelpers
import XCTest

@testable import BitwardenShared

@available(iOS 17.0, *)
class VaultAutofillListProcessorTotpTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
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
    var totpExpirationManagerForItems: MockTOTPExpirationManager!
    var totpExpirationManagerForSearchItems: MockTOTPExpirationManager!
    var totpExpirationManagerFactory: MockTOTPExpirationManagerFactory!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appExtensionDelegate = MockAutofillAppExtensionDelegate()
        appExtensionDelegate.extensionMode = .autofillOTP([
            .fixture(),
        ])
        authRepository = MockAuthRepository()
        clientService = MockClientService()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        fido2CredentialStore = MockFido2CredentialStore()
        fido2UserInterfaceHelper = MockFido2UserInterfaceHelper()
        stateService = MockStateService()

        totpExpirationManagerForItems = MockTOTPExpirationManager()
        totpExpirationManagerForSearchItems = MockTOTPExpirationManager()
        totpExpirationManagerFactory = MockTOTPExpirationManagerFactory()
        totpExpirationManagerFactory.createResults = [
            totpExpirationManagerForItems,
            totpExpirationManagerForSearchItems,
        ]

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

    /// `init(appExtensionDelegate:coordinator:services:state:)` initializes
    /// the state with totp.
    @MainActor
    func test_init() {
        XCTAssertTrue(subject.state.isAutofillingTotpList)
        XCTAssertEqual(totpExpirationManagerFactory.createTimesCalled, 2)
    }

    /// `perform(_:)` with `.search()` performs a cipher search and updates the state with the results.
    /// Also it configures TOTP refresh scheduling.
    @MainActor
    func test_perform_searchWithTOTPRefreshScheduling() {
        let items = [
            VaultListItem(
                id: "1",
                itemType: .totp(name: "test1", totpModel: VaultListTOTP.fixture(id: "1"))
            ),
            VaultListItem(
                id: "2",
                itemType: .totp(name: "test2", totpModel: VaultListTOTP.fixture(id: "2"))
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
        XCTAssertEqual(totpExpirationManagerForSearchItems.configuredTOTPRefreshSchedulingItems?.count, 2)
    }

    /// `perform(_:)` with `.streamAutofillItems` streams the list of autofill ciphers and configures
    /// TOTP refresh scheduling.
    @MainActor
    func test_perform_streamAutofillItemsWithTOTPRefreshScheduling() {
        let items = [
            VaultListItem(
                id: "1",
                itemType: .totp(name: "test1", totpModel: VaultListTOTP.fixture(id: "1"))
            ),
            VaultListItem(
                id: "2",
                itemType: .totp(name: "test2", totpModel: VaultListTOTP.fixture(id: "2"))
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
        XCTAssertEqual(totpExpirationManagerForItems.configuredTOTPRefreshSchedulingItems?.count, 2)
    }

    /// `refreshTOTPCodes(for:)` is called from the TOTP expiration manager expiration closure
    /// and refreshes the vault list sections.
    @MainActor
    func test_refreshTOTPCodes_forItems() { // swiftlint:disable:this function_body_length
        let items = [
            VaultListItem(
                id: "1",
                itemType: .totp(name: "test1", totpModel: VaultListTOTP.fixture(id: "1"))
            ),
            VaultListItem(
                id: "2",
                itemType: .totp(name: "test2", totpModel: VaultListTOTP.fixture(id: "2"))
            ),
        ]
        subject.state.vaultListSections = [
            VaultListSection(
                id: "",
                items: items,
                name: ""
            ),
        ]
        let refreshedItems = [
            VaultListItem(
                id: "2",
                itemType: .totp(name: "test2", totpModel: VaultListTOTP.fixture(
                    id: "2",
                    totpCode: .init(
                        code: "456789",
                        codeGenerationDate: Date(),
                        period: 30
                    )
                ))
            ),
        ]
        vaultRepository.refreshTOTPCodesResult = .success(refreshedItems)

        guard let onExpiration = totpExpirationManagerFactory.onExpirationClosures[0] else {
            XCTFail("There is no onExpiration closure for the first item in the factory")
            return
        }
        onExpiration(items.filter { $0.id == "2" })

        waitFor(totpExpirationManagerForItems.configuredTOTPRefreshSchedulingItems?.count == 2)
        XCTAssertEqual(subject.state.vaultListSections.count, 1)
        XCTAssertEqual(subject.state.vaultListSections[0].items.count, 2)

        let totpItem0 = subject.state.vaultListSections[0].items[0]
        guard case let .totp(name0, totpModel0) = totpItem0.itemType else {
            XCTFail("There is no TOTP item in the first section first item.")
            return
        }
        XCTAssertEqual(name0, "test1")
        XCTAssertEqual(totpModel0.totpCode.code, "123456")

        let totpItem1 = subject.state.vaultListSections[0].items[1]
        guard case let .totp(name1, totpModel1) = totpItem1.itemType else {
            XCTFail("There is no TOTP item in first section second item.")
            return
        }
        XCTAssertEqual(name1, "test2")
        XCTAssertEqual(totpModel1.totpCode.code, "456789")
    }

    /// `refreshTOTPCodes(for:)` does nothing if vault list sections are empty..
    @MainActor
    func test_refreshTOTPCodes_forItemsEmpty() {
        subject.state.vaultListSections = []

        guard let onExpiration = totpExpirationManagerFactory.onExpirationClosures[0] else {
            XCTFail("There is no onExpiration closure for the first item in the factory")
            return
        }
        onExpiration([])

        XCTAssertFalse(vaultRepository.refreshTOTPCodesCalled)
    }

    /// `refreshTOTPCodes(for:)` logs when refreshing throws.
    @MainActor
    func test_refreshTOTPCodes_forItemsThrows() {
        let items = [
            VaultListItem(
                id: "1",
                itemType: .totp(name: "test1", totpModel: VaultListTOTP.fixture(id: "1"))
            ),
            VaultListItem(
                id: "2",
                itemType: .totp(name: "test2", totpModel: VaultListTOTP.fixture(id: "2"))
            ),
        ]
        subject.state.vaultListSections = [
            VaultListSection(
                id: "",
                items: items,
                name: ""
            ),
        ]
        vaultRepository.refreshTOTPCodesResult = .failure(BitwardenTestError.example)

        guard let onExpiration = totpExpirationManagerFactory.onExpirationClosures[0] else {
            XCTFail("There is no onExpiration closure for the first item in the factory")
            return
        }
        onExpiration(items.filter { $0.id == "2" })

        waitFor(errorReporter.errors.last as? BitwardenTestError == BitwardenTestError.example)
    }

    /// `refreshTOTPCodes(searchItems:)` is called from the TOTP expiration manager expiration closure
    /// and refreshes the search list sections.
    @MainActor
    func test_refreshTOTPCodes_searchItems() { // swiftlint:disable:this function_body_length
        let items = [
            VaultListItem(
                id: "1",
                itemType: .totp(name: "test1", totpModel: VaultListTOTP.fixture(id: "1"))
            ),
            VaultListItem(
                id: "2",
                itemType: .totp(name: "test2", totpModel: VaultListTOTP.fixture(id: "2"))
            ),
        ]
        subject.state.ciphersForSearch = [
            VaultListSection(
                id: "",
                items: items,
                name: ""
            ),
        ]
        let refreshedItems = [
            VaultListItem(
                id: "2",
                itemType: .totp(name: "test2", totpModel: VaultListTOTP.fixture(
                    id: "2",
                    totpCode: .init(
                        code: "456789",
                        codeGenerationDate: Date(),
                        period: 30
                    )
                ))
            ),
        ]
        vaultRepository.refreshTOTPCodesResult = .success(refreshedItems)

        guard let onExpiration = totpExpirationManagerFactory.onExpirationClosures[1] else {
            XCTFail("There is no onExpiration closure for the second item in the factory")
            return
        }
        onExpiration(items.filter { $0.id == "2" })

        waitFor(totpExpirationManagerForSearchItems.configuredTOTPRefreshSchedulingItems?.count == 2)
        XCTAssertEqual(subject.state.ciphersForSearch.count, 1)
        XCTAssertEqual(subject.state.ciphersForSearch[0].items.count, 2)

        let totpItem0 = subject.state.ciphersForSearch[0].items[0]
        guard case let .totp(name0, totpModel0) = totpItem0.itemType else {
            XCTFail("There is no TOTP item in the first section first item.")
            return
        }
        XCTAssertEqual(name0, "test1")
        XCTAssertEqual(totpModel0.totpCode.code, "123456")

        let totpItem1 = subject.state.ciphersForSearch[0].items[1]
        guard case let .totp(name1, totpModel1) = totpItem1.itemType else {
            XCTFail("There is no TOTP item in first section second item.")
            return
        }
        XCTAssertEqual(name1, "test2")
        XCTAssertEqual(totpModel1.totpCode.code, "456789")
    }

    /// `refreshTOTPCodes(searchItems:)` does nothing if vault list sections are empty..
    @MainActor
    func test_refreshTOTPCodes_searchItemsEmpty() throws {
        // WORKAROUND: initialize `configuredTOTPRefreshSchedulingItems` with something so `waitFor`
        // doens't have race condition issues.
        totpExpirationManagerForSearchItems.configuredTOTPRefreshSchedulingItems = [
            VaultListItem(id: "1", itemType: .cipher(.fixture())),
        ]
        let items = [
            VaultListItem(
                id: "2",
                itemType: .totp(name: "test2", totpModel: VaultListTOTP.fixture(id: "2"))
            ),
        ]
        subject.state.ciphersForSearch = []
        let refreshedItems = [
            VaultListItem(
                id: "2",
                itemType: .totp(name: "test2", totpModel: VaultListTOTP.fixture(
                    id: "2",
                    totpCode: .init(
                        code: "456789",
                        codeGenerationDate: Date(),
                        period: 30
                    )
                ))
            ),
        ]
        vaultRepository.refreshTOTPCodesResult = .success(refreshedItems)

        guard let onExpiration = totpExpirationManagerFactory.onExpirationClosures[1] else {
            XCTFail("There is no onExpiration closure for the second item in the factory")
            return
        }
        onExpiration(items)

        waitFor(totpExpirationManagerForSearchItems.configuredTOTPRefreshSchedulingItems?.isEmpty == true)
        let ciphersForSearch = subject.state.ciphersForSearch
        let section = try XCTUnwrap(ciphersForSearch.first)
        XCTAssertEqual(ciphersForSearch.count, 1)
        XCTAssertEqual(section.items.count, 0)
    }

    /// `refreshTOTPCodes(searchItems:)` logs when refreshing throws.
    @MainActor
    func test_refreshTOTPCodes_searchItemsThrows() {
        let items = [
            VaultListItem(
                id: "1",
                itemType: .totp(name: "test1", totpModel: VaultListTOTP.fixture(id: "1"))
            ),
            VaultListItem(
                id: "2",
                itemType: .totp(name: "test2", totpModel: VaultListTOTP.fixture(id: "2"))
            ),
        ]
        subject.state.ciphersForSearch = [
            VaultListSection(
                id: "",
                items: items,
                name: ""
            ),
        ]
        vaultRepository.refreshTOTPCodesResult = .failure(BitwardenTestError.example)

        guard let onExpiration = totpExpirationManagerFactory.onExpirationClosures[1] else {
            XCTFail("There is no onExpiration closure for the second item in the factory")
            return
        }
        onExpiration(items.filter { $0.id == "2" })

        waitFor(errorReporter.errors.last as? BitwardenTestError == BitwardenTestError.example)
    }
} // swiftlint:disable:this file_length
