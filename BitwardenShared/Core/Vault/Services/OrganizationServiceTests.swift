import BitwardenKitMocks
import BitwardenSdk
import XCTest

@testable import BitwardenShared

class OrganizationServiceTests: XCTestCase {
    // MARK: Properties

    var clientService: MockClientService!
    var errorReporter: MockErrorReporter!
    var organizationDataStore: MockOrganizationDataStore!
    var subject: OrganizationService!
    var stateService: MockStateService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        clientService = MockClientService()
        errorReporter = MockErrorReporter()
        organizationDataStore = MockOrganizationDataStore()
        stateService = MockStateService()

        subject = DefaultOrganizationService(
            clientService: clientService,
            errorReporter: errorReporter,
            organizationDataStore: organizationDataStore,
            stateService: stateService
        )
    }

    override func tearDown() {
        super.tearDown()

        clientService = nil
        errorReporter = nil
        organizationDataStore = nil
        subject = nil
    }

    // MARK: Tests

    /// `fetchAllOrganizations()` returns all organizations for the active user.
    func test_fetchAllOrganizations() async throws {
        let organizations: [Organization] = [
            .fixture(id: "1", name: "Organization 1"),
            .fixture(id: "2", name: "Organization 2"),
            .fixture(id: "3", name: "Organization 3"),
        ]

        organizationDataStore.fetchAllOrganizationsResult = .success(organizations)
        stateService.activeAccount = .fixture()

        let fetchedOrganizations = try await subject.fetchAllOrganizations()

        XCTAssertEqual(fetchedOrganizations, organizations)
        XCTAssertEqual(organizationDataStore.fetchAllOrganizationsUserId, "1")
    }

    /// `fetchAllOrganizations(userId:)` returns all organizations for the user.
    func test_fetchAllOrganizations_userId() async throws {
        let organizations: [Organization] = [
            .fixture(id: "1", name: "Organization 1"),
            .fixture(id: "2", name: "Organization 2"),
            .fixture(id: "3", name: "Organization 3"),
        ]
        organizationDataStore.fetchAllOrganizationsResult = .success(organizations)

        let fetchedOrganizations = try await subject.fetchAllOrganizations(userId: "2")

        XCTAssertEqual(fetchedOrganizations, organizations)
        XCTAssertEqual(organizationDataStore.fetchAllOrganizationsUserId, "2")
    }

    /// `initializeOrganizationCrypto()` initializes the SDK for decrypting organization ciphers.
    func test_initializeOrganizationCrypto() async throws {
        organizationDataStore.fetchAllOrganizationsResult = .success([
            .fixture(id: "ORG_1", key: "ORG_1_KEY"),
            .fixture(id: "ORG_2", key: "ORG_2_KEY"),
        ])
        stateService.activeAccount = .fixture()

        try await subject.initializeOrganizationCrypto()

        XCTAssertEqual(
            clientService.mockCrypto.initializeOrgCryptoRequest,
            InitOrgCryptoRequest(organizationKeys: [
                "ORG_2": "ORG_2_KEY",
                "ORG_1": "ORG_1_KEY",
            ])
        )
    }

    /// `initializeOrganizationCrypto()` logs an error to the error reporter if initializing
    /// organization crypto fails.
    func test_initializeOrganizationCrypto_error() async throws {
        struct InitializeOrgCryptoError: Error {}

        clientService.mockCrypto.initializeOrgCryptoResult = .failure(InitializeOrgCryptoError())
        stateService.activeAccount = .fixture()

        try await subject.initializeOrganizationCrypto()

        XCTAssertTrue(errorReporter.errors.last is InitializeOrgCryptoError)
    }

    /// `initializeOrganizationCrypto()` initializes the SDK for decrypting organization ciphers
    /// with an empty dictionary if the user isn't a part of any organizations.
    func test_initializeOrganizationCrypto_noOrganizations() async throws {
        organizationDataStore.fetchAllOrganizationsResult = .success([])
        stateService.activeAccount = .fixture()

        try await subject.initializeOrganizationCrypto()

        XCTAssertEqual(
            clientService.mockCrypto.initializeOrgCryptoRequest,
            InitOrgCryptoRequest(organizationKeys: [:])
        )
    }

    /// `initializeOrganizationCrypto()` initializes the SDK for decrypting organization ciphers for
    /// a given set of organizations.
    func test_initializeOrganizationCrypto_withOrganizations() async throws {
        let organizations: [Organization] = [
            .fixture(id: "ORG_1", key: "ORG_1_KEY"),
            .fixture(id: "ORG_2", key: "ORG_2_KEY"),
        ]

        try await subject.initializeOrganizationCrypto(organizations: organizations)

        XCTAssertEqual(
            clientService.mockCrypto.initializeOrgCryptoRequest,
            InitOrgCryptoRequest(organizationKeys: [
                "ORG_2": "ORG_2_KEY",
                "ORG_1": "ORG_1_KEY",
            ])
        )
    }

    /// `organizationsPublisher()` returns a publisher that emits data as the data store changes.
    func test_organizationsPublisher() async throws {
        stateService.activeAccount = .fixtureAccountLogin()

        var iterator = try await subject.organizationsPublisher().values.makeAsyncIterator()
        _ = try await iterator.next()

        let organization = Organization.fixture()
        organizationDataStore.organizationSubject.value = [organization]
        let publisherValue = try await iterator.next()
        try XCTAssertEqual(XCTUnwrap(publisherValue), [organization])
    }

    /// `replaceOrganizations(_:userId:)` replaces the persisted organizations in the data store.
    func test_replaceOrganizations() async throws {
        let organizations: [ProfileOrganizationResponseModel] = [
            .fixture(id: "1", name: "Organization 1"),
            .fixture(id: "2", name: "Organization 2"),
        ]

        try await subject.replaceOrganizations(organizations, userId: "1")

        XCTAssertEqual(organizationDataStore.replaceOrganizationsValue, organizations)
        XCTAssertEqual(organizationDataStore.replaceOrganizationsUserId, "1")
    }
}
