import CoreData
import XCTest

@testable import BitwardenShared

class PolicyDataStoreTests: BitwardenTestCase {
    // MARK: Properties

    var subject: DataStore!

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

    /// `deleteAllPolicies(user:)` removes all objects for the user.
    func test_deleteAllPolicies() async throws {
        try await insertPolicies(policies, userId: "1")
        try await insertPolicies(policies, userId: "2")

        try await subject.deleteAllPolicies(userId: "1")

        try XCTAssertTrue(fetchPolicies(userId: "1").isEmpty)
        try XCTAssertEqual(fetchPolicies(userId: "2").count, 2)
    }

    /// `fetchAllPolicies(userId:)` fetches all policies for a user.
    func test_fetchAllPolicies() async throws {
        try await insertPolicies(policies, userId: "1")

        let fetchedPolicies = try await subject.fetchAllPolicies(userId: "1")
        XCTAssertEqual(fetchedPolicies, policies.map(Policy.init))

        let emptyPolicies = try await subject.fetchAllPolicies(userId: "-1")
        XCTAssertEqual(emptyPolicies, [])
    }

    /// `replacePolicies(_:userId:)` replaces the list of policies for the user.
    func test_replacePolicies() async throws {
        try await subject.replacePolicies(policies, userId: "1")

        let fetchedPolicies = try await subject.fetchAllPolicies(userId: "1")
        XCTAssertEqual(fetchedPolicies, policies.map(Policy.init))
    }

    // MARK: Test Helpers

    /// A test helper to fetch all policies for a user.
    private func fetchPolicies(userId: String) throws -> [Policy] {
        let fetchRequest = PolicyData.fetchByUserIdRequest(userId: userId)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \PolicyData.id, ascending: true)]
        return try subject.backgroundContext.fetch(fetchRequest).compactMap(Policy.init)
    }

    /// A test helper for inserting a list of policies for a user.
    private func insertPolicies(_ policies: [PolicyResponseModel], userId: String) async throws {
        try await subject.backgroundContext.performAndSave {
            for policy in policies {
                _ = PolicyData(context: self.subject.backgroundContext, userId: userId, policy: policy)
            }
        }
    }
}
