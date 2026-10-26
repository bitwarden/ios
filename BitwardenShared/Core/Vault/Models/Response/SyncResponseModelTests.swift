import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - SyncResponseModelTests

struct SyncResponseModelTests {
    // MARK: effectivePolicies

    /// `effectivePolicies` returns an empty list when both `policies` and `policiesNew` are absent.
    @Test
    func effectivePolicies_bothListsAbsent() {
        let subject = SyncResponseModel.fixture(
            policies: nil,
            policiesNew: nil,
        )
        #expect(subject.effectivePolicies.isEmpty)
    }

    /// `effectivePolicies` uses `policies` when `policiesNew` is absent.
    @Test
    func effectivePolicies_fallsBackToPolicies() {
        let subject = SyncResponseModel.fixture(
            policies: [.fixture(id: "legacy")],
            policiesNew: nil,
        )
        #expect(subject.effectivePolicies.map(\.id) == ["legacy"])
    }

    /// `effectivePolicies` prefers `policiesNew` over `policies` when both are present.
    @Test
    func effectivePolicies_prefersPoliciesNew() {
        let subject = SyncResponseModel.fixture(
            policies: [.fixture(id: "legacy")],
            policiesNew: [.fixture(id: "new")],
        )
        #expect(subject.effectivePolicies.map(\.id) == ["new"])
    }

    /// `effectivePolicies` returns an empty list when `policiesNew` is present but empty, rather
    /// than falling back to `policies`.
    @Test
    func effectivePolicies_policiesNewEmpty() {
        let subject = SyncResponseModel.fixture(
            policies: [.fixture(id: "legacy")],
            policiesNew: [],
        )
        #expect(subject.effectivePolicies.isEmpty)
    }
}
