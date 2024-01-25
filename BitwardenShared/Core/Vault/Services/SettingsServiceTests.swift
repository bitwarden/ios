import XCTest

@testable import BitwardenShared

class SettingsServiceTests: XCTestCase {
    // MARK: Properties

    var settingsDataStore: MockSettingsDataStore!
    var stateService: MockStateService!
    var subject: DefaultSettingsService!

    let domains = DomainsResponseModel(
        equivalentDomains: [["google.com", "youtube.com"]],
        globalEquivalentDomains: [
            GlobalDomains(domains: ["apple.com", "icloud.com"], excluded: false, type: 0),
        ]
    )

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        settingsDataStore = MockSettingsDataStore()
        stateService = MockStateService()

        subject = DefaultSettingsService(
            settingsDataStore: settingsDataStore,
            stateService: stateService
        )
    }

    override func tearDown() {
        super.tearDown()

        settingsDataStore = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `fetchEquivalentDomains()` returns the list of persisted equivalent domains.
    func test_fetchEquivalentDomains() async throws {
        stateService.activeAccount = .fixture()

        var fetchedDomains = try await subject.fetchEquivalentDomains()
        XCTAssertEqual(fetchedDomains, [])

        settingsDataStore.fetchDomainsResult = .success(
            DomainsResponseModel(equivalentDomains: nil, globalEquivalentDomains: nil)
        )
        fetchedDomains = try await subject.fetchEquivalentDomains()
        XCTAssertEqual(fetchedDomains, [])

        settingsDataStore.fetchDomainsResult = .success(domains)
        fetchedDomains = try await subject.fetchEquivalentDomains()
        XCTAssertEqual(
            fetchedDomains,
            [
                ["google.com", "youtube.com"],
                ["apple.com", "icloud.com"],
            ]
        )
    }

    /// `replaceEquivalentDomains(_:userId:)` replaces the persisted domains in the data store.
    func test_replaceEquivalentDomains() async throws {
        try await subject.replaceEquivalentDomains(domains, userId: "1")

        XCTAssertEqual(settingsDataStore.replaceDomainsDomains, domains)
    }

    /// `replaceEquivalentDomains(_:userId:)` deletes the persisted domains in the data store if the data is `nil`.
    func test_replaceEquivalentDomains_nil() async throws {
        try await subject.replaceEquivalentDomains(nil, userId: "1")

        XCTAssertTrue(settingsDataStore.deleteEquivalentDomainsCalled)
        XCTAssertEqual(settingsDataStore.deleteEquivalentDomainsUserId, "1")
    }
}
