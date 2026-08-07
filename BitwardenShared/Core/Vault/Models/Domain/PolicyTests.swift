import Foundation
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

struct PolicyTests {
    // MARK: Tests

    /// `earliestRevisionDate` returns `nil` for an empty list.
    @Test
    func earliestRevisionDate_empty() {
        let policies: [Policy] = []
        #expect(policies.earliestRevisionDate == nil)
    }

    /// `earliestRevisionDate` returns the policy with the earliest revision date.
    @Test
    func earliestRevisionDate_multiplePolicies() {
        let earliest = Policy.fixture(id: "policy-2", revisionDate: Date(year: 2024, month: 1, day: 10))
        let policies = [
            Policy.fixture(id: "policy-1", revisionDate: Date(year: 2024, month: 3, day: 15)),
            earliest,
            Policy.fixture(id: "policy-3", revisionDate: Date(year: 2024, month: 2, day: 20)),
        ]

        #expect(policies.earliestRevisionDate == earliest)
    }

    /// `earliestRevisionDate` treats a `nil` revision date as `.distantFuture`, so a policy with an
    /// actual date is preferred over one with a `nil` date.
    @Test
    func earliestRevisionDate_nilRevisionDate() {
        let earliest = Policy.fixture(id: "policy-2", revisionDate: Date(year: 2024, month: 1, day: 10))
        let policies = [
            Policy.fixture(id: "policy-1", revisionDate: nil),
            earliest,
        ]

        #expect(policies.earliestRevisionDate == earliest)
    }
}
