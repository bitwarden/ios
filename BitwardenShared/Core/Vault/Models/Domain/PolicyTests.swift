import Foundation
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

struct PolicyTests {
    // MARK: Tests

    /// `init(responseModel:)` initializes a policy from a response model with a known type.
    @Test
    func init_responseModel() {
        let subject = Policy(responseModel: .fixture(type: .disableSend))
        #expect(subject == .fixture(organizationId: "org-1", type: .disableSend))
    }

    /// `init(responseModel:)` returns `nil` for a response model with an unrecognized type.
    @Test
    func init_responseModel_unknownType() {
        var responseModel = PolicyResponseModel.fixture()
        responseModel.$type = .unknown(99)
        #expect(Policy(responseModel: responseModel) == nil)
    }

    /// `init(responseModel:)` returns `nil` for a response model with a missing type.
    @Test
    func init_responseModel_missingType() {
        #expect(Policy(responseModel: .fixture(type: nil)) == nil)
    }

    /// `policyWithEarliestRevisionDate` returns `nil` for an empty list.
    @Test
    func policyWithEarliestRevisionDate_empty() {
        let policies: [Policy] = []
        #expect(policies.policyWithEarliestRevisionDate == nil)
    }

    /// `policyWithEarliestRevisionDate` returns the policy with the earliest revision date.
    @Test
    func policyWithEarliestRevisionDate_multiplePolicies() {
        let earliest = Policy.fixture(id: "policy-2", revisionDate: Date(year: 2024, month: 1, day: 10))
        let policies = [
            Policy.fixture(id: "policy-1", revisionDate: Date(year: 2024, month: 3, day: 15)),
            earliest,
            Policy.fixture(id: "policy-3", revisionDate: Date(year: 2024, month: 2, day: 20)),
        ]

        #expect(policies.policyWithEarliestRevisionDate == earliest)
    }

    /// `policyWithEarliestRevisionDate` treats a `nil` revision date as `.distantFuture`, so a policy with an
    /// actual date is preferred over one with a `nil` date.
    @Test
    func policyWithEarliestRevisionDate_nilRevisionDate() {
        let earliest = Policy.fixture(id: "policy-2", revisionDate: Date(year: 2024, month: 1, day: 10))
        let policies = [
            Policy.fixture(id: "policy-1", revisionDate: nil),
            earliest,
        ]

        #expect(policies.policyWithEarliestRevisionDate == earliest)
    }
}
