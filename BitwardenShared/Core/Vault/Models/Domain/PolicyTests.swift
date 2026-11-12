import Foundation
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

struct PolicyTests {
    // MARK: Tests

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
