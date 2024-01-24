import XCTest

@testable import BitwardenShared

class PolicyServiceTests: XCTestCase {
    // MARK: Properties

    var policyDataStore: MockPolicyDataStore!
    var stateService: MockStateService!
    var subject: DefaultPolicyService!

    let policies: [PolicyResponseModel] = [
        .fixture(id: "1"),
        .fixture(id: "2"),
    ]

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        policyDataStore = MockPolicyDataStore()
        stateService = MockStateService()

        subject = DefaultPolicyService(
            policyDataStore: policyDataStore,
            stateService: stateService
        )
    }

    override func tearDown() {
        super.tearDown()

        policyDataStore = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `replacePolicies(_:userId:)` replaces the persisted policies in the data store.
    func test_replacePolicies() async throws {
        try await subject.replacePolicies(policies, userId: "1")

        XCTAssertEqual(policyDataStore.replacePoliciesPolicies, policies)
    }
}
