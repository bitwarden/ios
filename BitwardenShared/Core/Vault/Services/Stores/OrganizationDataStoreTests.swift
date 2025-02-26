import BitwardenSdk
import CoreData
import XCTest

@testable import BitwardenShared

class OrganizationDataStoreTests: BitwardenTestCase {
    // MARK: Properties

    var subject: DataStore!

    let organizations = [
        ProfileOrganizationResponseModel.fixture(id: "1", name: "ORGANIZATION1"),
        ProfileOrganizationResponseModel.fixture(id: "2", name: "ORGANIZATION2"),
        ProfileOrganizationResponseModel.fixture(id: "3", name: "ORGANIZATION3"),
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

    /// `deleteAllOrganizations(user:)` removes all objects for the user.
    func test_deleteAllOrganizations() async throws {
        try await insertOrganizations(organizations, userId: "1")
        try await insertOrganizations(organizations, userId: "2")

        try await subject.deleteAllOrganizations(userId: "1")

        try XCTAssertTrue(fetchOrganizations(userId: "1").isEmpty)
        try XCTAssertEqual(fetchOrganizations(userId: "2").count, 3)
    }

    /// `organizationPublisher(userId:)` returns a publisher for a user's organization objects.
    func test_organizationPublisher() async throws {
        var publishedValues = [[Organization]]()
        let publisher = subject.organizationPublisher(userId: "1")
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { values in
                    publishedValues.append(values)
                }
            )
        defer { publisher.cancel() }

        try await subject.replaceOrganizations(organizations, userId: "1")

        waitFor { publishedValues.count == 2 }
        XCTAssertTrue(publishedValues[0].isEmpty)
        XCTAssertEqual(publishedValues[1], organizations.compactMap(Organization.init))
    }

    /// `fetchAllOrganizations(userId:)` fetches all organizations for a user.
    func test_fetchAllOrganizations() async throws {
        try await insertOrganizations(organizations, userId: "1")

        let fetchedOrganizations = try await subject.fetchAllOrganizations(userId: "1")
        XCTAssertEqual(
            fetchedOrganizations.sorted(using: KeyPathComparator(\.id)),
            organizations.compactMap(Organization.init)
        )

        let emptyOrganizations = try await subject.fetchAllOrganizations(userId: "-1")
        XCTAssertEqual(emptyOrganizations, [])
    }

    /// `replaceOrganizations(_:userId)` replaces the list of organizations for the user.
    func test_replaceOrganizations() async throws {
        try await insertOrganizations(organizations, userId: "1")

        let newOrganizations = [
            ProfileOrganizationResponseModel.fixture(id: "3", name: "ORGANIZATION3"),
            ProfileOrganizationResponseModel.fixture(id: "4", name: "ORGANIZATION4"),
            ProfileOrganizationResponseModel.fixture(id: "5", name: "ORGANIZATION5"),
        ]
        try await subject.replaceOrganizations(newOrganizations, userId: "1")

        XCTAssertEqual(try fetchOrganizations(userId: "1"), newOrganizations.compactMap(Organization.init))
    }

    // MARK: Test Helpers

    /// A test helper to fetch all organization's for a user.
    private func fetchOrganizations(userId: String) throws -> [Organization] {
        let fetchRequest = OrganizationData.fetchByUserIdRequest(userId: userId)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \OrganizationData.id, ascending: true)]
        return try subject.backgroundContext.fetch(fetchRequest).compactMap(Organization.init)
    }

    /// A test helper for inserting a list of organizations for a user.
    private func insertOrganizations(_ organizations: [ProfileOrganizationResponseModel], userId: String) async throws {
        try await subject.backgroundContext.performAndSave {
            for organization in organizations {
                _ = OrganizationData(
                    context: self.subject.backgroundContext,
                    userId: userId,
                    organization: organization
                )
            }
        }
    }
}
