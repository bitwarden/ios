import XCTest

@testable import BitwardenShared

class PolicyServiceTests: BitwardenTestCase {
    // MARK: Properties

    var organizationService: MockOrganizationService!
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

        organizationService = MockOrganizationService()
        policyDataStore = MockPolicyDataStore()
        stateService = MockStateService()

        subject = DefaultPolicyService(
            organizationService: organizationService,
            policyDataStore: policyDataStore,
            stateService: stateService
        )
    }

    override func tearDown() {
        super.tearDown()

        organizationService = nil
        policyDataStore = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `policyAppliesToUser(_:)` returns whether the policy applies to the user.
    func test_policyAppliesToUser() async {
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesResult = .success([.fixture(type: .twoFactorAuthentication)])

        let twoFactorApplies = await subject.policyAppliesToUser(.twoFactorAuthentication)
        XCTAssertTrue(twoFactorApplies)

        let onlyOrgApplies = await subject.policyAppliesToUser(.onlyOrg)
        XCTAssertFalse(onlyOrgApplies)
    }

    /// `policyAppliesToUser(_:)` returns whether the policy applies to the user when one
    /// organization has the policy enabled but not another.
    func test_policyAppliesToUser_multipleOrganizations() async {
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture(id: "org-1"), .fixture(id: "org-2")])
        policyDataStore.fetchPoliciesResult = .success([
            .fixture(enabled: false, organizationId: "org-1", type: .twoFactorAuthentication),
            .fixture(enabled: true, organizationId: "org-2", type: .twoFactorAuthentication),
        ])

        let policyApplies = await subject.policyAppliesToUser(.twoFactorAuthentication)
        XCTAssertTrue(policyApplies)
    }

    /// `policyAppliesToUser(_:)` returns whether the policy applies to the user when there's
    /// multiple policies.
    func test_policyAppliesToUser_multiplePolicies() async {
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesResult = .success([
            .fixture(type: .twoFactorAuthentication),
            .fixture(type: .onlyOrg),
        ])

        let twoFactorApplies = await subject.policyAppliesToUser(.twoFactorAuthentication)
        XCTAssertTrue(twoFactorApplies)

        let onlyOrgApplies = await subject.policyAppliesToUser(.onlyOrg)
        XCTAssertTrue(onlyOrgApplies)

        let disablePersonalVaultExportApplies = await subject.policyAppliesToUser(.disablePersonalVaultExport)
        XCTAssertFalse(disablePersonalVaultExportApplies)
    }

    /// `policyAppliesToUser(_:)` returns whether the policy applies to the user when there's no
    /// organizations.
    func test_policyAppliesToUser_noOrganizations() async {
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([])
        policyDataStore.fetchPoliciesResult = .success([.fixture(type: .twoFactorAuthentication)])

        let policyApplies = await subject.policyAppliesToUser(.twoFactorAuthentication)
        XCTAssertFalse(policyApplies)
    }

    /// `policyAppliesToUser(_:)` returns whether the policy applies to the user when there's no
    /// policies.
    func test_policyAppliesToUser_noPolicies() async {
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesResult = .success([])

        let policyApplies = await subject.policyAppliesToUser(.twoFactorAuthentication)
        XCTAssertFalse(policyApplies)
    }

    /// `policyAppliesToUser(_:)` returns whether the policy applies to the user when the
    /// organization user is exempt from policies.
    func test_policyAppliesToUser_organizationExempt() async {
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture(type: .admin)])
        policyDataStore.fetchPoliciesResult = .success([.fixture(type: .twoFactorAuthentication)])

        let policyApplies = await subject.policyAppliesToUser(.twoFactorAuthentication)
        XCTAssertFalse(policyApplies)
    }

    /// `policyAppliesToUser(_:)` returns whether the policy applies to the user when the
    /// organization doesn't use policies.
    func test_policyAppliesToUser_organizationDoesNotUsePolicies() async {
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture(usePolicies: false)])
        policyDataStore.fetchPoliciesResult = .success([.fixture(type: .twoFactorAuthentication)])

        let policyApplies = await subject.policyAppliesToUser(.twoFactorAuthentication)
        XCTAssertFalse(policyApplies)
    }

    /// `policyAppliesToUser(_:)` returns whether the policy applies to the user when the
    /// organization isn't enabled.
    func test_policyAppliesToUser_organizationNotEnabled() async {
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture(enabled: false)])
        policyDataStore.fetchPoliciesResult = .success([.fixture(type: .twoFactorAuthentication)])

        let policyApplies = await subject.policyAppliesToUser(.twoFactorAuthentication)
        XCTAssertFalse(policyApplies)
    }

    /// `policyAppliesToUser(_:)` returns whether the policy applies to the user when the user is
    /// only invited to the organization.
    func test_policyAppliesToUser_organizationInvited() async {
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture(status: .invited)])
        policyDataStore.fetchPoliciesResult = .success([.fixture(type: .twoFactorAuthentication)])

        let policyApplies = await subject.policyAppliesToUser(.twoFactorAuthentication)
        XCTAssertFalse(policyApplies)
    }

    /// `replacePolicies(_:userId:)` replaces the persisted policies in the data store.
    func test_replacePolicies() async throws {
        try await subject.replacePolicies(policies, userId: "1")

        XCTAssertEqual(policyDataStore.replacePoliciesPolicies, policies)
    }

    /// `replacePolicies(_:userId:)` updates the cached list of policies for the user.
    func test_replacePolicies_updatesPolicyAppliesToUser() async throws {
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture(id: "org-1")])
        policyDataStore.fetchPoliciesResult = .success([])

        var policyApplies = await subject.policyAppliesToUser(.twoFactorAuthentication)
        XCTAssertFalse(policyApplies)

        try await subject.replacePolicies(
            [.fixture(type: .twoFactorAuthentication)],
            userId: "1"
        )

        policyApplies = await subject.policyAppliesToUser(.twoFactorAuthentication)
        XCTAssertTrue(policyApplies)
    }
}
