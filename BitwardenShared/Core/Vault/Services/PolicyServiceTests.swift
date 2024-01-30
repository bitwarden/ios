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

    let passwordGeneratorPolicy = Policy.fixture(
        data: [
            PolicyOptionType.capitalize.rawValue: .bool(true),
            PolicyOptionType.defaultType.rawValue: .string(PasswordGeneratorType.passphrase.rawValue),
            PolicyOptionType.includeNumber.rawValue: .bool(false),
            PolicyOptionType.minLength.rawValue: .int(30),
            PolicyOptionType.minNumbers.rawValue: .int(3),
            PolicyOptionType.minNumberWords.rawValue: .int(4),
            PolicyOptionType.minSpecial.rawValue: .int(2),
            PolicyOptionType.useLower.rawValue: .bool(true),
            PolicyOptionType.useNumbers.rawValue: .bool(false),
            PolicyOptionType.useSpecial.rawValue: .bool(true),
            PolicyOptionType.useUpper.rawValue: .bool(false),
        ],
        type: .passwordGenerator
    )

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

    /// `applyPasswordGenerationOptions(options:)` applies the password generation policy to the
    /// options when there's multiple policies.
    func test_applyPasswordGenerationOptions_multiplePolicies() async throws {
        stateService.activeAccount = .fixture()
        policyDataStore.fetchPoliciesResult = .success(
            [
                .fixture(
                    data: [
                        PolicyOptionType.capitalize.rawValue: .bool(false),
                        PolicyOptionType.includeNumber.rawValue: .bool(true),
                        PolicyOptionType.minLength.rawValue: .int(20),
                        PolicyOptionType.minNumbers.rawValue: .int(5),
                    ],
                    type: .passwordGenerator
                ),
                passwordGeneratorPolicy,
            ]
        )

        var options = PasswordGenerationOptions()
        let appliedPolicy = try await subject.applyPasswordGenerationPolicy(options: &options)

        XCTAssertTrue(appliedPolicy)
        XCTAssertEqual(
            options,
            PasswordGenerationOptions(
                capitalize: true,
                includeNumber: true,
                length: 30,
                lowercase: true,
                minNumber: 5,
                minSpecial: 2,
                number: nil,
                numWords: 4,
                special: true,
                type: .passphrase,
                uppercase: nil
            )
        )
    }

    /// `applyPasswordGenerationOptions(options:)` doesn't modify the password generation options
    /// when there's no policies.
    func test_applyPasswordGenerationOptions_noPolicies() async throws {
        stateService.activeAccount = .fixture()

        let options = PasswordGenerationOptions(length: 10, lowercase: true, number: true, uppercase: false)
        var policyEnforcedOptions = options
        let appliedPolicy = try await subject.applyPasswordGenerationPolicy(options: &policyEnforcedOptions)

        XCTAssertFalse(appliedPolicy)
        XCTAssertEqual(policyEnforcedOptions, options)
    }

    /// `applyPasswordGenerationOptions(options:)` applies the password generation policy to the
    /// options.
    func test_applyPasswordGenerationOptions_policy() async throws {
        stateService.activeAccount = .fixture()
        policyDataStore.fetchPoliciesResult = .success([passwordGeneratorPolicy])

        var options = PasswordGenerationOptions()
        let appliedPolicy = try await subject.applyPasswordGenerationPolicy(options: &options)

        XCTAssertTrue(appliedPolicy)
        XCTAssertEqual(
            options,
            PasswordGenerationOptions(
                capitalize: true,
                includeNumber: nil,
                length: 30,
                lowercase: true,
                minNumber: 3,
                minSpecial: 2,
                number: nil,
                numWords: 4,
                special: true,
                type: .passphrase,
                uppercase: nil
            )
        )
    }

    /// `applyPasswordGenerationOptions(options:)` applies the password generation policy to the
    /// options when there's existing options.
    func test_applyPasswordGenerationOptions_policy_existingOptions() async throws {
        stateService.activeAccount = .fixture()
        policyDataStore.fetchPoliciesResult = .success([passwordGeneratorPolicy])

        var options = PasswordGenerationOptions(
            capitalize: false,
            includeNumber: true,
            length: 45,
            minSpecial: 5,
            special: false,
            type: .password,
            uppercase: true
        )
        let appliedPolicy = try await subject.applyPasswordGenerationPolicy(options: &options)

        XCTAssertTrue(appliedPolicy)
        XCTAssertEqual(
            options,
            PasswordGenerationOptions(
                capitalize: true,
                includeNumber: true,
                length: 45,
                lowercase: true,
                minNumber: 3,
                minSpecial: 5,
                number: nil,
                numWords: 4,
                special: true,
                type: .password,
                uppercase: true
            )
        )
    }

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
