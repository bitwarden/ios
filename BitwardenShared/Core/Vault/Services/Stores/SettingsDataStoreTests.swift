import CoreData
import XCTest

@testable import BitwardenShared

class SettingsDataStoreTests: BitwardenTestCase {
    // MARK: Properties

    var subject: DataStore!

    let domains = DomainsResponseModel(
        equivalentDomains: [["google.com", "youtube.com"]],
        globalEquivalentDomains: [
            GlobalDomains(domains: ["apple.com", "icloud.com"], excluded: false, type: 0),
        ]
    )

    let policies: [PolicyResponseModel] = [
        PolicyResponseModel(
            data: nil,
            enabled: true,
            id: "1",
            organizationId: "org-1",
            type: .twoFactorAuthentication
        ),
        PolicyResponseModel(
            data: nil,
            enabled: true,
            id: "2",
            organizationId: "org-1",
            type: .masterPassword
        ),
    ]

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = DataStore(errorReporter: MockErrorReporter(), storeType: .memory)
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `deleteEquivalentDomains(userId:)` removes the domains for the user.
    func test_deleteEquivalentDomains() async throws {
        try await subject.replaceEquivalentDomains(domains, userId: "1")
        try await subject.replaceEquivalentDomains(domains, userId: "2")

        try await subject.deleteEquivalentDomains(userId: "1")

        var fetchedDomains = try await subject.fetchEquivalentDomains(userId: "1")
        XCTAssertNil(fetchedDomains)
        fetchedDomains = try await subject.fetchEquivalentDomains(userId: "2")
        XCTAssertEqual(fetchedDomains, domains)
    }

    /// `fetchDomains(userId:` fetches the domains for the user.
    func test_fetchEquivalentDomains() async throws {
        try await subject.replaceEquivalentDomains(domains, userId: "1")
        let fetchedDomains = try await subject.fetchEquivalentDomains(userId: "1")
        XCTAssertEqual(fetchedDomains, domains)
    }

    /// `replaceEquivalentDomains(_:userId:)` replaces the list of domains for the user.
    func test_replaceEquivalentDomains() async throws {
        try await subject.replaceEquivalentDomains(
            DomainsResponseModel(equivalentDomains: nil, globalEquivalentDomains: nil),
            userId: "1"
        )

        try await subject.replaceEquivalentDomains(domains, userId: "1")

        let fetchedDomains = try await subject.fetchEquivalentDomains(userId: "1")
        XCTAssertEqual(fetchedDomains, domains)
    }
}
