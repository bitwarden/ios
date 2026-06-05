import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - ProfileResponseModelTests

struct ProfileResponseModelTests {
    // MARK: effectiveOrganizations

    /// `effectiveOrganizations` returns `nil` when both `organizations` and `organizationsNew` are absent.
    @Test
    func effectiveOrganizations_bothListsAbsent() {
        let subject = ProfileResponseModel.fixture(
            organizations: nil,
            organizationsNew: nil,
        )
        #expect(subject.effectiveOrganizations == nil)
    }

    /// `effectiveOrganizations` uses `organizations` when `organizationsNew` is absent.
    @Test
    func effectiveOrganizations_fallsBackToOrganizations() {
        let org = ProfileOrganizationResponseModel.fixture(id: "org-1")
        let subject = ProfileResponseModel.fixture(
            organizations: [org],
            organizationsNew: nil,
        )
        #expect(subject.effectiveOrganizations?.map(\.id) == ["org-1"])
    }

    /// `effectiveOrganizations` prefers `organizationsNew` over `organizations` when both are present.
    @Test
    func effectiveOrganizations_prefersOrganizationsNew() {
        let legacyOrg = ProfileOrganizationResponseModel.fixture(id: "legacy")
        let newOrg = ProfileOrganizationResponseModel.fixture(id: "new")
        let subject = ProfileResponseModel.fixture(
            organizations: [legacyOrg],
            organizationsNew: [newOrg],
        )
        #expect(subject.effectiveOrganizations?.map(\.id) == ["new"])
    }

    /// `effectiveOrganizations` returns the list unchanged when `providerOrganizations` is absent.
    @Test
    func effectiveOrganizations_noProviderOrgs_returnsUnchanged() {
        let org = ProfileOrganizationResponseModel.fixture(id: "org-1", isProviderUser: false)
        let subject = ProfileResponseModel.fixture(
            organizations: [org],
            providerOrganizations: nil,
        )
        #expect(subject.effectiveOrganizations?.first?.isProviderUser == false)
    }

    /// `effectiveOrganizations` returns the list unchanged when `providerOrganizations` is empty.
    @Test
    func effectiveOrganizations_emptyProviderOrgs_returnsUnchanged() {
        let org = ProfileOrganizationResponseModel.fixture(id: "org-1", isProviderUser: false)
        let subject = ProfileResponseModel.fixture(
            organizations: [org],
            providerOrganizations: [],
        )
        #expect(subject.effectiveOrganizations?.first?.isProviderUser == false)
    }

    /// `effectiveOrganizations` sets `isProviderUser` to `true` on organizations whose ID
    /// appears in `providerOrganizations`.
    @Test
    func effectiveOrganizations_setsIsProviderUserForMatchingOrg() {
        let org = ProfileOrganizationResponseModel.fixture(id: "org-1", isProviderUser: false)
        let providerOrg = ProfileProviderOrganizationResponseModel(id: "org-1")
        let subject = ProfileResponseModel.fixture(
            organizations: [org],
            providerOrganizations: [providerOrg],
        )
        #expect(subject.effectiveOrganizations?.first?.isProviderUser == true)
    }

    /// `effectiveOrganizations` does not alter `isProviderUser` on organizations whose ID
    /// is not present in `providerOrganizations`.
    @Test
    func effectiveOrganizations_doesNotAlterNonMatchingOrg() {
        let org = ProfileOrganizationResponseModel.fixture(id: "org-1", isProviderUser: false)
        let providerOrg = ProfileProviderOrganizationResponseModel(id: "org-2")
        let subject = ProfileResponseModel.fixture(
            organizations: [org],
            providerOrganizations: [providerOrg],
        )
        #expect(subject.effectiveOrganizations?.first?.isProviderUser == false)
    }

    /// `effectiveOrganizations` correctly marks only the matching org when the list contains
    /// both provider and non-provider organizations.
    @Test
    func effectiveOrganizations_mixedOrgs_onlyMarksMatching() {
        let providerOrg = ProfileOrganizationResponseModel.fixture(id: "org-provider")
        let regularOrg = ProfileOrganizationResponseModel.fixture(id: "org-regular")
        let providerRelationship = ProfileProviderOrganizationResponseModel(id: "org-provider")
        let subject = ProfileResponseModel.fixture(
            organizations: [providerOrg, regularOrg],
            providerOrganizations: [providerRelationship],
        )

        let result = subject.effectiveOrganizations
        #expect(result?.count == 2)
        #expect(result?.first(where: { $0.id == "org-provider" })?.isProviderUser == true)
        #expect(result?.first(where: { $0.id == "org-regular" })?.isProviderUser == false)
    }
}
