import BitwardenKit
import BitwardenKitMocks
import BitwardenSdk
import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

@MainActor
class PolicyServiceTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var clientService: MockClientService!
    var configService: MockConfigService!
    var errorReporter: MockErrorReporter!
    var organizationService: MockOrganizationService!
    var policyDataStore: MockPolicyDataStore!
    var stateService: MockStateService!
    var subject: DefaultPolicyService!

    let masterPasswordPolicy = Policy.fixture(
        data: [
            PolicyOptionType.minLength.rawValue: .int(30),
            PolicyOptionType.requireUpper.rawValue: .bool(true),
            PolicyOptionType.requireLower.rawValue: .bool(true),
            PolicyOptionType.enforceOnLogin.rawValue: .bool(true),
        ],
        type: .masterPassword,
    )

    let policies: [PolicyResponseModel] = [
        .fixture(id: "1"),
        .fixture(id: "2"),
    ]

    let maximumTimeoutPolicy = Policy.fixture(
        data: [
            PolicyOptionType.action.rawValue: .string("lock"),
            PolicyOptionType.minutes.rawValue: .int(60),
            PolicyOptionType.type.rawValue: .string("custom"),
        ],
        type: .maximumVaultTimeout,
    )

    let maximumTimeoutPolicyNoAction = Policy.fixture(
        data: [PolicyOptionType.minutes.rawValue: .int(60)],
        type: .maximumVaultTimeout,
    )

    let maximumTimeoutPolicyLogout = Policy.fixture(
        data: [
            PolicyOptionType.action.rawValue: .string("logOut"),
            PolicyOptionType.minutes.rawValue: .int(60),
            PolicyOptionType.type.rawValue: .string("custom"),
        ],
        type: .maximumVaultTimeout,
    )

    let passwordGeneratorPolicy = Policy.fixture(
        data: [
            PolicyOptionType.capitalize.rawValue: .bool(true),
            PolicyOptionType.overridePasswordType.rawValue: .string(PasswordGeneratorType.passphrase.rawValue),
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
        type: .passwordGenerator,
    )

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        clientService = MockClientService()
        configService = MockConfigService()
        errorReporter = MockErrorReporter()
        organizationService = MockOrganizationService()
        policyDataStore = MockPolicyDataStore()
        stateService = MockStateService()

        subject = DefaultPolicyService(
            clientService: clientService,
            configService: configService,
            errorReporter: errorReporter,
            organizationService: organizationService,
            policyDataStore: policyDataStore,
            stateService: stateService,
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()

        clientService = nil
        configService = nil
        errorReporter = nil
        organizationService = nil
        policyDataStore = nil
        stateService = nil
        subject = nil
    }

    // MARK: Test Helpers

    /// Stubs the mock SDK policies client to return the enabled policies matching the requested
    /// type, mirroring the part of `PoliciesClient.filterByType`'s contract that doesn't depend on
    /// organization context.
    ///
    /// Tests for logic *downstream* of the filter use this to get realistic input without
    /// re-asserting the organization-context filtering (membership status, role exemptions,
    /// `usePolicies`) that the SDK owns and tests. Tests that verify what the service hands *to*
    /// the SDK skip this and assert on `filterByTypeReceivedArguments` instead.
    ///
    private func stubSdkFilterByType() {
        clientService.mockPolicies.filterByTypeClosure = { policies, _, policyType in
            policies.filter { $0.enabled && $0.type == policyType }
        }
    }

    // MARK: Tests

    /// `applyPasswordGenerationOptions(options:)` applies the password generation policy to the
    /// options and if the existing option has a type set, the policies will override that.
    func test_applyPasswordGenerationOptions_overridePasswordType_existingOption() async throws {
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success([passwordGeneratorPolicy])
        stubSdkFilterByType()

        var options = PasswordGenerationOptions(type: .password)
        let appliedPolicy = try await subject.applyPasswordGenerationPolicy(options: &options)

        XCTAssertEqual(options.type, .passphrase)
        XCTAssertTrue(appliedPolicy)
    }

    /// `applyPasswordGenerationOptions(options:)` applies the password generation policy to the
    /// options when there's multiple policies.
    func test_applyPasswordGenerationOptions_multiplePolicies() async throws {
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success(
            [
                .fixture(
                    data: [
                        PolicyOptionType.capitalize.rawValue: .bool(false),
                        PolicyOptionType.includeNumber.rawValue: .bool(true),
                        PolicyOptionType.minLength.rawValue: .int(20),
                        PolicyOptionType.minNumbers.rawValue: .int(5),
                    ],
                    type: .passwordGenerator,
                ),
                passwordGeneratorPolicy,
            ],
        )
        stubSdkFilterByType()

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
                uppercase: nil,
                overridePasswordType: true,
            ),
        )
    }

    /// `applyPasswordGenerationOptions(options:)` applies the password generation policy to the
    /// options when there's multiple policies and the password generator type should take priority.
    func test_applyPasswordGenerationOptions_multiplePolicies_differentTypes() async throws {
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success(
            [
                passwordGeneratorPolicy,
                .fixture(
                    data: [
                        PolicyOptionType.overridePasswordType.rawValue:
                            .string(PasswordGeneratorType.password.rawValue),
                    ],
                    type: .passwordGenerator,
                ),
                .fixture(
                    data: [
                        PolicyOptionType.overridePasswordType.rawValue:
                            .string(PasswordGeneratorType.passphrase.rawValue),
                    ],
                    type: .passwordGenerator,
                ),
            ],
        )
        stubSdkFilterByType()

        var options = PasswordGenerationOptions()
        let appliedPolicy = try await subject.applyPasswordGenerationPolicy(options: &options)

        XCTAssertEqual(options.type, .password)
        XCTAssertTrue(appliedPolicy)
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
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success([passwordGeneratorPolicy])
        stubSdkFilterByType()

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
                uppercase: nil,
                overridePasswordType: true,
            ),
        )
    }

    /// `applyPasswordGenerationOptions(options:)` applies the password generation policy to the
    /// options.
    func test_applyPasswordGenerationOptions_policy_noOverride() async throws {
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success(
            [
                .fixture(
                    data: [:],
                    type: .passwordGenerator,
                ),
            ],
        )
        stubSdkFilterByType()

        var options = PasswordGenerationOptions()
        let appliedPolicy = try await subject.applyPasswordGenerationPolicy(options: &options)

        XCTAssertTrue(appliedPolicy)
        XCTAssertEqual(options.overridePasswordType, false)
    }

    /// `applyPasswordGenerationOptions(options:)` applies the password generation policy to the
    /// options when there's existing options.
    func test_applyPasswordGenerationOptions_policy_existingOptions() async throws {
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success([passwordGeneratorPolicy])
        stubSdkFilterByType()

        var options = PasswordGenerationOptions(
            capitalize: false,
            includeNumber: true,
            length: 45,
            minSpecial: 5,
            special: false,
            type: .password,
            uppercase: true,
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
                type: .passphrase,
                uppercase: true,
                overridePasswordType: true,
            ),
        )
    }

    /// `getMasterPasswordPolicyOptions()` returns `nil` if there is no master password policy type exist.
    func test_getMasterPasswordPolicyOptions_nil() async throws {
        let policy = try await subject.getMasterPasswordPolicyOptions()
        XCTAssertNil(policy)
    }

    /// `getMasterPasswordPolicyOptions()` returns `MasterPasswordPolicyOptions` if there is
    ///  master password policy type exist.
    func test_getMasterPasswordPolicyOptions_success() async throws {
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success([masterPasswordPolicy])
        stubSdkFilterByType()

        let policy = try await subject.getMasterPasswordPolicyOptions()
        XCTAssertNotNil(policy)
        let safePolicy = try XCTUnwrap(policy)
        XCTAssertEqual(safePolicy.minLength, 30)
        XCTAssertEqual(safePolicy.minComplexity, 0)
        XCTAssertEqual(safePolicy.enforceOnLogin, true)
        XCTAssertEqual(safePolicy.requireLower, true)
        XCTAssertEqual(safePolicy.requireUpper, true)
        XCTAssertEqual(safePolicy.requireSpecial, false)
        XCTAssertEqual(safePolicy.requireNumbers, false)
    }

    // MARK: - getEarliestOrganizationApplyingPolicy Tests

    /// `getEarliestOrganizationApplyingPolicy()` returns nil when no policies apply.
    func test_getEarliestOrganizationApplyingPolicy_noPolicies() async {
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success([])
        stubSdkFilterByType()

        let organizationId = await subject.getEarliestOrganizationApplyingPolicy(.personalOwnership)

        XCTAssertNil(organizationId)
    }

    /// `getEarliestOrganizationApplyingPolicy()` returns the organization ID when a single policy applies.
    func test_getEarliestOrganizationApplyingPolicy_singlePolicy() async {
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture(id: "org-1")])
        policyDataStore.fetchPoliciesNewResult = .success([
            .fixture(
                id: "policy-1",
                organizationId: "org-1",
                revisionDate: Date(year: 2024, month: 1, day: 15),
                type: .personalOwnership,
            ),
        ])
        stubSdkFilterByType()

        let organizationId = await subject.getEarliestOrganizationApplyingPolicy(.personalOwnership)

        XCTAssertEqual(organizationId, "org-1")
    }

    /// `getEarliestOrganizationApplyingPolicy()` returns the organization with the earliest revision date.
    func test_getEarliestOrganizationApplyingPolicy_multipleOrganizations_earliestFirst() async {
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([
            .fixture(id: "org-1"),
            .fixture(id: "org-2"),
            .fixture(id: "org-3"),
        ])
        policyDataStore.fetchPoliciesNewResult = .success([
            .fixture(
                id: "policy-1",
                organizationId: "org-1",
                revisionDate: Date(year: 2024, month: 3, day: 15),
                type: .personalOwnership,
            ),
            .fixture(
                id: "policy-2",
                organizationId: "org-2",
                revisionDate: Date(year: 2024, month: 1, day: 10), // Earliest
                type: .personalOwnership,
            ),
            .fixture(
                id: "policy-3",
                organizationId: "org-3",
                revisionDate: Date(year: 2024, month: 2, day: 20),
                type: .personalOwnership,
            ),
        ])
        stubSdkFilterByType()

        let organizationId = await subject.getEarliestOrganizationApplyingPolicy(.personalOwnership)

        XCTAssertEqual(organizationId, "org-2")
    }

    /// `getEarliestOrganizationApplyingPolicy()` handles policies with nil revision dates.
    func test_getEarliestOrganizationApplyingPolicy_nilRevisionDates() async {
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([
            .fixture(id: "org-1"),
            .fixture(id: "org-2"),
        ])
        policyDataStore.fetchPoliciesNewResult = .success([
            .fixture(
                id: "policy-1",
                organizationId: "org-1",
                revisionDate: nil, // nil revision date should be treated as distant future
                type: .personalOwnership,
            ),
            .fixture(
                id: "policy-2",
                organizationId: "org-2",
                revisionDate: Date(year: 2024, month: 1, day: 10),
                type: .personalOwnership,
            ),
        ])
        stubSdkFilterByType()

        let organizationId = await subject.getEarliestOrganizationApplyingPolicy(.personalOwnership)

        XCTAssertEqual(organizationId, "org-2")
    }

    /// `getEarliestOrganizationApplyingPolicy()` returns an organization when all policies have nil revision dates.
    func test_getEarliestOrganizationApplyingPolicy_allNilRevisionDates() async {
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([
            .fixture(id: "org-1"),
            .fixture(id: "org-2"),
            .fixture(id: "org-3"),
        ])
        policyDataStore.fetchPoliciesNewResult = .success([
            .fixture(
                id: "policy-1",
                organizationId: "org-1",
                revisionDate: nil,
                type: .personalOwnership,
            ),
            .fixture(
                id: "policy-2",
                organizationId: "org-2",
                revisionDate: nil,
                type: .personalOwnership,
            ),
            .fixture(
                id: "policy-3",
                organizationId: "org-3",
                revisionDate: nil,
                type: .personalOwnership,
            ),
        ])
        stubSdkFilterByType()

        let organizationId = await subject.getEarliestOrganizationApplyingPolicy(.personalOwnership)

        // When all policies have nil revisionDate (treated as distantFuture), any organization is acceptable
        XCTAssertNotNil(organizationId)
    }

    /// `getEarliestOrganizationApplyingPolicy()` returns nil when no active account.
    func test_getEarliestOrganizationApplyingPolicy_noActiveAccount() async {
        stateService.activeAccount = nil

        let organizationId = await subject.getEarliestOrganizationApplyingPolicy(.personalOwnership)

        XCTAssertNil(organizationId)
    }

    /// `getEarliestOrganizationApplyingPolicy()` only considers policies of the specified type.
    func test_getEarliestOrganizationApplyingPolicy_onlyMatchingPolicyType() async {
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([
            .fixture(id: "org-1"),
            .fixture(id: "org-2"),
        ])
        policyDataStore.fetchPoliciesNewResult = .success([
            .fixture(
                id: "policy-1",
                organizationId: "org-1",
                revisionDate: Date(year: 2024, month: 1, day: 1), // Earlier but wrong type
                type: .twoFactorAuthentication,
            ),
            .fixture(
                id: "policy-2",
                organizationId: "org-2",
                revisionDate: Date(year: 2024, month: 6, day: 15),
                type: .personalOwnership,
            ),
        ])
        stubSdkFilterByType()

        let organizationId = await subject.getEarliestOrganizationApplyingPolicy(.personalOwnership)

        XCTAssertEqual(organizationId, "org-2")
    }

    // MARK: - getSendPolicyOptions (allowedDomains) Tests

    /// `getSendPolicyOptions()` surfaces the allowed domains from the Send Controls policy when
    /// email verification is enforced.
    func test_getSendPolicyOptions_allowedDomains() async {
        configService.featureFlagsBool[.sendControls] = true
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success(
            [
                .fixture(
                    data: [
                        PolicyOptionType.whoCanAccess.rawValue: .int(2),
                        PolicyOptionType.allowedDomains.rawValue: .string("acme.com, acme.co"),
                    ],
                    type: .sendControls,
                ),
            ],
        )
        stubSdkFilterByType()

        let options = await subject.getSendPolicyOptions()
        XCTAssertEqual(options.allowedDomains, ["acme.com", "acme.co"])
    }

    /// When the Send Controls feature flag is disabled, `getSendPolicyOptions()` surfaces no allowed
    /// domains.
    func test_getSendPolicyOptions_allowedDomains_flagOff() async {
        configService.featureFlagsBool[.sendControls] = false
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success(
            [
                .fixture(
                    data: [
                        PolicyOptionType.whoCanAccess.rawValue: .int(2),
                        PolicyOptionType.allowedDomains.rawValue: .string("acme.com"),
                    ],
                    type: .sendControls,
                ),
            ],
        )
        stubSdkFilterByType()

        let options = await subject.getSendPolicyOptions()
        XCTAssertTrue(options.allowedDomains.isEmpty)
    }

    // MARK: - getSendPolicyOptions (enforcedAccessType) Tests

    /// `getSendPolicyOptions()` enforces the "anyone with password" access type when the Send
    /// Controls policy's `whoCanAccess` is `1` (PasswordProtected).
    func test_getSendPolicyOptions_enforcedAccessType_passwordProtected() async {
        configService.featureFlagsBool[.sendControls] = true
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success(
            [
                .fixture(
                    data: [PolicyOptionType.whoCanAccess.rawValue: .int(1)],
                    type: .sendControls,
                ),
            ],
        )
        stubSdkFilterByType()

        let options = await subject.getSendPolicyOptions()
        XCTAssertEqual(options.enforcedAccessType, .anyoneWithPassword)
    }

    /// `getSendPolicyOptions()` enforces the "specific people" access type when the Send Controls
    /// policy's `whoCanAccess` is `2` (SpecificPeople).
    func test_getSendPolicyOptions_enforcedAccessType_specificPeople() async {
        configService.featureFlagsBool[.sendControls] = true
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success(
            [
                .fixture(
                    data: [PolicyOptionType.whoCanAccess.rawValue: .int(2)],
                    type: .sendControls,
                ),
            ],
        )
        stubSdkFilterByType()

        let options = await subject.getSendPolicyOptions()
        XCTAssertEqual(options.enforcedAccessType, .specificPeople)
    }

    /// `getSendPolicyOptions()` enforces no access type when the Send Controls policy's `whoCanAccess`
    /// is `0` (Any).
    func test_getSendPolicyOptions_enforcedAccessType_any() async {
        configService.featureFlagsBool[.sendControls] = true
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success(
            [
                .fixture(
                    data: [PolicyOptionType.whoCanAccess.rawValue: .int(0)],
                    type: .sendControls,
                ),
            ],
        )
        stubSdkFilterByType()

        let options = await subject.getSendPolicyOptions()
        XCTAssertNil(options.enforcedAccessType)
    }

    /// `getSendPolicyOptions()` enforces no access type when the Send Controls policy doesn't contain
    /// a `whoCanAccess` value.
    func test_getSendPolicyOptions_enforcedAccessType_optionNoData() async {
        configService.featureFlagsBool[.sendControls] = true
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success([.fixture(type: .sendControls)])
        stubSdkFilterByType()

        let options = await subject.getSendPolicyOptions()
        XCTAssertNil(options.enforcedAccessType)
    }

    /// `getSendPolicyOptions()` enforces no access type when there's no policies.
    func test_getSendPolicyOptions_enforcedAccessType_noPolicies() async {
        configService.featureFlagsBool[.sendControls] = true
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success([])
        stubSdkFilterByType()

        let options = await subject.getSendPolicyOptions()
        XCTAssertNil(options.enforcedAccessType)
    }

    /// When the Send Controls feature flag is disabled, `getSendPolicyOptions()` enforces no access
    /// type even when a `sendControls` policy sets `whoCanAccess`.
    func test_getSendPolicyOptions_enforcedAccessType_flagOff() async {
        configService.featureFlagsBool[.sendControls] = false
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success(
            [
                .fixture(
                    data: [PolicyOptionType.whoCanAccess.rawValue: .int(1)],
                    type: .sendControls,
                ),
            ],
        )
        stubSdkFilterByType()

        let options = await subject.getSendPolicyOptions()
        XCTAssertNil(options.enforcedAccessType)
    }

    // MARK: - getSendPolicyOptions (enforcedSendType) Tests

    /// `getSendPolicyOptions()` maps a single-type `allowedSendTypes` array to the enforced Send type.
    func test_getSendPolicyOptions_enforcedSendType() async {
        configService.featureFlagsBool[.sendControls] = true
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success(
            [
                .fixture(
                    data: [PolicyOptionType.allowedSendTypes.rawValue: .array([.int(1)])],
                    type: .sendControls,
                ),
            ],
        )
        stubSdkFilterByType()

        let options = await subject.getSendPolicyOptions()
        XCTAssertEqual(options.enforcedSendType, .file)
    }

    /// `getSendPolicyOptions()` enforces no Send type when both types are allowed.
    func test_getSendPolicyOptions_enforcedSendType_bothAllowed() async {
        configService.featureFlagsBool[.sendControls] = true
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success(
            [
                .fixture(
                    data: [PolicyOptionType.allowedSendTypes.rawValue: .array([.int(0), .int(1)])],
                    type: .sendControls,
                ),
            ],
        )
        stubSdkFilterByType()

        let options = await subject.getSendPolicyOptions()
        XCTAssertNil(options.enforcedSendType)
    }

    /// When the Send Controls feature flag is disabled, `getSendPolicyOptions()` enforces no Send type.
    func test_getSendPolicyOptions_enforcedSendType_flagOff() async {
        configService.featureFlagsBool[.sendControls] = false
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success(
            [
                .fixture(
                    data: [PolicyOptionType.allowedSendTypes.rawValue: .array([.int(1)])],
                    type: .sendControls,
                ),
            ],
        )
        stubSdkFilterByType()

        let options = await subject.getSendPolicyOptions()
        XCTAssertNil(options.enforcedSendType)
    }

    // MARK: - getSendPolicyOptions (isHideEmailDisabled) Tests

    /// `getSendPolicyOptions()` reports the hide email option disabled when the Send Controls policy
    /// disables it.
    func test_getSendPolicyOptions_isHideEmailDisabled() async {
        configService.featureFlagsBool[.sendControls] = true
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success(
            [
                .fixture(
                    data: [PolicyOptionType.disableHideEmail.rawValue: .bool(true)],
                    type: .sendControls,
                ),
            ],
        )
        stubSdkFilterByType()

        let options = await subject.getSendPolicyOptions()
        XCTAssertTrue(options.isHideEmailDisabled)
    }

    /// `getSendPolicyOptions()` reports the hide email option enabled if there's no policies.
    func test_getSendPolicyOptions_isHideEmailDisabled_noPolicies() async {
        configService.featureFlagsBool[.sendControls] = true
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success([])
        stubSdkFilterByType()

        let options = await subject.getSendPolicyOptions()
        XCTAssertFalse(options.isHideEmailDisabled)
    }

    /// `getSendPolicyOptions()` reports the hide email option enabled if the disable hide email
    /// option is disabled.
    func test_getSendPolicyOptions_isHideEmailDisabled_optionDisabled() async {
        configService.featureFlagsBool[.sendControls] = true
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success(
            [
                .fixture(
                    data: [PolicyOptionType.disableHideEmail.rawValue: .bool(false)],
                    type: .sendControls,
                ),
            ],
        )
        stubSdkFilterByType()

        let options = await subject.getSendPolicyOptions()
        XCTAssertFalse(options.isHideEmailDisabled)
    }

    /// `getSendPolicyOptions()` reports the hide email option enabled if the policy doesn't contain
    /// any custom data.
    func test_getSendPolicyOptions_isHideEmailDisabled_optionNoData() async {
        configService.featureFlagsBool[.sendControls] = true
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success([.fixture(type: .sendControls)])
        stubSdkFilterByType()

        let options = await subject.getSendPolicyOptions()
        XCTAssertFalse(options.isHideEmailDisabled)
    }

    /// When the Send Controls feature flag is disabled, `getSendPolicyOptions()` reads the hide email
    /// option from the legacy `sendOptions` policy and ignores any `sendControls` policy.
    func test_getSendPolicyOptions_isHideEmailDisabled_flagOff() async {
        configService.featureFlagsBool[.sendControls] = false
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success(
            [
                .fixture(
                    data: [PolicyOptionType.disableHideEmail.rawValue: .bool(false)],
                    type: .sendControls,
                ),
                .fixture(
                    data: [PolicyOptionType.disableHideEmail.rawValue: .bool(true)],
                    type: .sendOptions,
                ),
            ],
        )
        stubSdkFilterByType()

        let options = await subject.getSendPolicyOptions()
        XCTAssertTrue(options.isHideEmailDisabled)
    }

    // MARK: - getSendPolicyOptions (isSendDisabled) Tests

    /// `getSendPolicyOptions()` reports Sends disabled when the Send Controls policy's `disableSend`
    /// option is enabled.
    func test_getSendPolicyOptions_isSendDisabled() async {
        configService.featureFlagsBool[.sendControls] = true
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success(
            [
                .fixture(
                    data: [PolicyOptionType.disableSend.rawValue: .bool(true)],
                    type: .sendControls,
                ),
            ],
        )
        stubSdkFilterByType()

        let options = await subject.getSendPolicyOptions()
        XCTAssertTrue(options.isSendDisabled)
    }

    /// `getSendPolicyOptions()` reports Sends enabled when the Send Controls policy's `disableSend`
    /// option is disabled.
    func test_getSendPolicyOptions_isSendDisabled_optionDisabled() async {
        configService.featureFlagsBool[.sendControls] = true
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success(
            [
                .fixture(
                    data: [PolicyOptionType.disableSend.rawValue: .bool(false)],
                    type: .sendControls,
                ),
            ],
        )
        stubSdkFilterByType()

        let options = await subject.getSendPolicyOptions()
        XCTAssertFalse(options.isSendDisabled)
    }

    /// `getSendPolicyOptions()` reports Sends enabled when the Send Controls policy doesn't contain
    /// any custom data.
    func test_getSendPolicyOptions_isSendDisabled_optionNoData() async {
        configService.featureFlagsBool[.sendControls] = true
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success([.fixture(type: .sendControls)])
        stubSdkFilterByType()

        let options = await subject.getSendPolicyOptions()
        XCTAssertFalse(options.isSendDisabled)
    }

    /// `getSendPolicyOptions()` reports Sends enabled when there's no policies.
    func test_getSendPolicyOptions_isSendDisabled_noPolicies() async {
        configService.featureFlagsBool[.sendControls] = true
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success([])
        stubSdkFilterByType()

        let options = await subject.getSendPolicyOptions()
        XCTAssertFalse(options.isSendDisabled)
    }

    /// `getSendPolicyOptions()` ignores the legacy `disableSend` policy, which is superseded by the
    /// Send Controls policy.
    func test_getSendPolicyOptions_isSendDisabled_ignoresLegacyDisableSendPolicy() async {
        configService.featureFlagsBool[.sendControls] = true
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success([.fixture(type: .disableSend)])
        stubSdkFilterByType()

        let options = await subject.getSendPolicyOptions()
        XCTAssertFalse(options.isSendDisabled)
    }

    /// When the Send Controls feature flag is disabled, `getSendPolicyOptions()` reports Sends
    /// disabled based on the legacy `disableSend` policy.
    func test_getSendPolicyOptions_isSendDisabled_flagOff() async {
        configService.featureFlagsBool[.sendControls] = false
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success([.fixture(type: .disableSend)])
        stubSdkFilterByType()

        let options = await subject.getSendPolicyOptions()
        XCTAssertTrue(options.isSendDisabled)
    }

    /// When the Send Controls feature flag is disabled, `getSendPolicyOptions()` reports Sends
    /// enabled when no policies apply.
    func test_getSendPolicyOptions_isSendDisabled_flagOff_noPolicies() async {
        configService.featureFlagsBool[.sendControls] = false
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success([])
        stubSdkFilterByType()

        let options = await subject.getSendPolicyOptions()
        XCTAssertFalse(options.isSendDisabled)
    }

    /// When the Send Controls feature flag is disabled, `getSendPolicyOptions()` ignores the Send
    /// Controls policy when determining whether Sends are disabled.
    func test_getSendPolicyOptions_isSendDisabled_flagOff_ignoresSendControlsPolicy() async {
        configService.featureFlagsBool[.sendControls] = false
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success(
            [
                .fixture(
                    data: [PolicyOptionType.disableSend.rawValue: .bool(true)],
                    type: .sendControls,
                ),
            ],
        )
        stubSdkFilterByType()

        let options = await subject.getSendPolicyOptions()
        XCTAssertFalse(options.isSendDisabled)
    }

    /// `fetchTimeoutPolicyValues()` fetches timeout values when the policy contains data.
    func test_fetchTimeoutPolicyValues() async throws {
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success([maximumTimeoutPolicy])
        stubSdkFilterByType()

        let policyValues = try await subject.fetchTimeoutPolicyValues()

        XCTAssertEqual(policyValues?.timeoutValue?.rawValue, 60)
        XCTAssertEqual(policyValues?.timeoutAction, .lock)
    }

    /// `fetchTimeoutPolicyValues()` fetches timeout values when the policy contains data.
    func test_fetchTimeoutPolicyValues_logout() async throws {
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success([maximumTimeoutPolicyLogout])
        stubSdkFilterByType()

        let policyValues = try await subject.fetchTimeoutPolicyValues()

        XCTAssertEqual(policyValues?.timeoutAction, .logout)
        XCTAssertEqual(policyValues?.timeoutType, .custom)
        XCTAssertEqual(policyValues?.timeoutValue?.rawValue, 60)
    }

    /// `fetchTimeoutPolicyValues()` fetches timeout values
    /// when the policy contains a value but no action.
    func test_fetchTimeoutPolicyValues_noAction() async throws {
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success([maximumTimeoutPolicyNoAction])
        stubSdkFilterByType()

        let policyValues = try await subject.fetchTimeoutPolicyValues()

        XCTAssertEqual(policyValues?.timeoutValue?.rawValue, 60)
        XCTAssertNil(policyValues?.timeoutAction)
    }

    /// `organizationsApplyingPolicyToUser(_:)` returns the organization IDs which apply the policy.
    func test_organizationsApplyingPolicyToUser() async {
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([
            .fixture(id: "org-1"),
            .fixture(id: "org-2"),
        ])
        policyDataStore.fetchPoliciesNewResult = .success([
            .fixture(enabled: false, organizationId: "org-1", type: .twoFactorAuthentication),
            .fixture(enabled: true, organizationId: "org-2", type: .twoFactorAuthentication),
        ])
        stubSdkFilterByType()

        let organizations = await subject.organizationsApplyingPolicyToUser(.twoFactorAuthentication)
        XCTAssertEqual(organizations, ["org-2"])
    }

    /// `policyAppliesToUser(_:)` returns whether the policy applies to the user.
    func test_policyAppliesToUser() async {
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success([.fixture(type: .twoFactorAuthentication)])
        stubSdkFilterByType()

        let twoFactorApplies = await subject.policyAppliesToUser(.twoFactorAuthentication)
        XCTAssertTrue(twoFactorApplies)

        let onlyOrgApplies = await subject.policyAppliesToUser(.onlyOrg)
        XCTAssertFalse(onlyOrgApplies)
    }

    /// `policyAppliesToUser()` called concurrently doesn't crash.
    func test_policyAppliesToUser_calledConcurrently() async {
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success([.fixture(type: .twoFactorAuthentication)])
        stubSdkFilterByType()

        // Calling `policyAppliesToUser(_:)` concurrently shouldn't throw an exception due to
        // simultaneous access to shared state. Since it's a race condition, running it repeatedly
        // should expose the failure if it's going to fail.
        for _ in 0 ..< 5 {
            async let concurrentTask1 = subject.policyAppliesToUser(.twoFactorAuthentication)
            async let concurrentTask2 = subject.policyAppliesToUser(.twoFactorAuthentication)

            _ = await (concurrentTask1, concurrentTask2)
        }
    }

    /// `policyAppliesToUser(_:)` returns whether the policy applies to the user when one
    /// organization has the policy enabled but not another.
    func test_policyAppliesToUser_multipleOrganizations() async {
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture(id: "org-1"), .fixture(id: "org-2")])
        policyDataStore.fetchPoliciesNewResult = .success([
            .fixture(enabled: false, organizationId: "org-1", type: .twoFactorAuthentication),
            .fixture(enabled: true, organizationId: "org-2", type: .twoFactorAuthentication),
        ])
        stubSdkFilterByType()

        let policyApplies = await subject.policyAppliesToUser(.twoFactorAuthentication)
        XCTAssertTrue(policyApplies)
    }

    /// `policyAppliesToUser(_:)` returns whether the policy applies to the user when there's
    /// multiple policies.
    func test_policyAppliesToUser_multiplePolicies() async {
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success([
            .fixture(type: .twoFactorAuthentication),
            .fixture(type: .onlyOrg),
        ])
        stubSdkFilterByType()

        let twoFactorApplies = await subject.policyAppliesToUser(.twoFactorAuthentication)
        XCTAssertTrue(twoFactorApplies)

        let onlyOrgApplies = await subject.policyAppliesToUser(.onlyOrg)
        XCTAssertTrue(onlyOrgApplies)

        let disablePersonalVaultExportApplies = await subject.policyAppliesToUser(.disablePersonalVaultExport)
        XCTAssertFalse(disablePersonalVaultExportApplies)
    }

    /// `policyAppliesToUser(_:)` returns whether the policy applies to the user when there's no
    /// policies.
    func test_policyAppliesToUser_noPolicies() async {
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success([])
        stubSdkFilterByType()

        let policyApplies = await subject.policyAppliesToUser(.twoFactorAuthentication)
        XCTAssertFalse(policyApplies)
    }

    /// `replacePolicies(_:userId:)` replaces the persisted policies in the data store.
    func test_replacePolicies() async throws {
        try await subject.replacePolicies(policies, userId: "1")

        XCTAssertEqual(policyDataStore.replacePoliciesPolicies, policies)
    }

    /// `replacePoliciesNew(_:userId:)` replaces the persisted accepted-state policies in the data store.
    func test_replacePoliciesNew() async throws {
        try await subject.replacePoliciesNew(policies, userId: "1")

        XCTAssertEqual(policyDataStore.replacePoliciesNewPolicies, policies)
    }

    /// `getOrganizationIdsForRestricItemTypesPolicy()` returns the policies that apply to the user.
    func test_getOrganizationIdsForRestricItemTypesPolicy() async {
        let result: Policy = .fixture(type: .restrictItemTypes)
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success([result])
        stubSdkFilterByType()

        let twoFactorPolicies: [String] = await subject.getOrganizationIdsForRestricItemTypesPolicy()
        XCTAssertEqual(twoFactorPolicies, [result.organizationId])
    }

    /// `getOrganizationIdsForRestricItemTypesPolicy()` called concurrently doesn't crash.
    func test_getOrganizationIdsForRestricItemTypesPolicy_calledConcurrently() async {
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success([.fixture(type: .twoFactorAuthentication)])
        stubSdkFilterByType()

        // Calling `policyAppliesToUser(_:)` concurrently shouldn't throw an exception due to
        // simultaneous access to shared state. Since it's a race condition, running it repeatedly
        // should expose the failure if it's going to fail.
        for _ in 0 ..< 5 {
            async let concurrentTask1 = subject.getOrganizationIdsForRestricItemTypesPolicy()
            async let concurrentTask2 = subject.getOrganizationIdsForRestricItemTypesPolicy()

            _ = await (concurrentTask1, concurrentTask2)
        }
    }

    /// `getOrganizationIdsForRestricItemTypesPolicy()` returns the policies that apply to the user when one
    /// organization has the policy enabled but not another.
    func test_getOrganizationIdsForRestricItemTypesPolicy_multipleOrganizations() async {
        let result: Policy = .fixture(enabled: true, organizationId: "org-2", type: .restrictItemTypes)
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture(id: "org-1"), .fixture(id: "org-2")])
        policyDataStore.fetchPoliciesNewResult = .success([
            .fixture(enabled: false, organizationId: "org-1", type: .twoFactorAuthentication),
            result,
        ])
        stubSdkFilterByType()

        let policies = await subject.getOrganizationIdsForRestricItemTypesPolicy()
        XCTAssertEqual(policies, [result.organizationId])
    }

    /// `getOrganizationIdsForRestricItemTypesPolicy_noOrganizations(_:)` returns the policies that apply to
    /// the user when there's no policies.
    func test_getOrganizationIdsForRestricItemTypesPolicy_noOrganizations_noPolicies() async {
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success([])
        stubSdkFilterByType()

        let policies = await subject.getOrganizationIdsForRestricItemTypesPolicy()
        XCTAssertTrue(policies.isEmpty)
    }

    // MARK: - getOrganizationUserNotificationBannerData Tests

    /// `getOrganizationUserNotificationBannerData()` returns `nil` when the feature flag is off.
    func test_getOrganizationUserNotificationBannerData_featureFlagOff() async {
        configService.featureFlagsBool[.organizationUserNotificationBanner] = false
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success([
            .fixture(
                data: [PolicyOptionType.description.rawValue: .string("Test message")],
                type: .organizationUserNotification,
            ),
        ])
        stubSdkFilterByType()

        let result = await subject.getOrganizationUserNotificationBannerData()
        XCTAssertNil(result)
    }

    /// `getOrganizationUserNotificationBannerData()` returns `nil` when the policy has no `description` field.
    func test_getOrganizationUserNotificationBannerData_missingDescription() async {
        configService.featureFlagsBool[.organizationUserNotificationBanner] = true
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success([
            .fixture(data: nil, type: .organizationUserNotification),
        ])
        stubSdkFilterByType()

        let result = await subject.getOrganizationUserNotificationBannerData()
        XCTAssertNil(result)
    }

    /// `getOrganizationUserNotificationBannerData()` uses the policy with the earliest revision date
    /// when multiple organizations apply the policy.
    func test_getOrganizationUserNotificationBannerData_multipleOrgs_usesEarliestRevisionDate() async {
        configService.featureFlagsBool[.organizationUserNotificationBanner] = true
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([
            .fixture(id: "org-1"),
            .fixture(id: "org-2"),
        ])
        policyDataStore.fetchPoliciesNewResult = .success([
            .fixture(
                data: [PolicyOptionType.description.rawValue: .string("Later org message.")],
                organizationId: "org-1",
                revisionDate: Date(year: 2024, month: 6, day: 1),
                type: .organizationUserNotification,
            ),
            .fixture(
                data: [PolicyOptionType.description.rawValue: .string("Earlier org message.")],
                organizationId: "org-2",
                revisionDate: Date(year: 2024, month: 1, day: 1),
                type: .organizationUserNotification,
            ),
        ])
        stubSdkFilterByType()

        let result = await subject.getOrganizationUserNotificationBannerData()
        XCTAssertEqual(result?.description, "Earlier org message.")
    }

    /// `getOrganizationUserNotificationBannerData()` returns `nil` when no matching policy applies.
    func test_getOrganizationUserNotificationBannerData_noPolicy() async {
        configService.featureFlagsBool[.organizationUserNotificationBanner] = true
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success([])
        stubSdkFilterByType()

        let result = await subject.getOrganizationUserNotificationBannerData()
        XCTAssertNil(result)
    }

    /// `getOrganizationUserNotificationBannerData()` returns the correct data when the policy is valid.
    func test_getOrganizationUserNotificationBannerData_validPolicy() async {
        let revisionDate = Date(year: 2024, month: 6, day: 1)
        configService.featureFlagsBool[.organizationUserNotificationBanner] = true
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success([
            .fixture(
                data: [
                    PolicyOptionType.header.rawValue: .string("Important Notice"),
                    PolicyOptionType.description.rawValue: .string("Please review your settings."),
                    PolicyOptionType.buttonText.rawValue: .string("I understand"),
                    PolicyOptionType.showAfterEveryLogin.rawValue: .bool(true),
                ],
                revisionDate: revisionDate,
                type: .organizationUserNotification,
            ),
        ])
        stubSdkFilterByType()

        let result = await subject.getOrganizationUserNotificationBannerData()
        XCTAssertEqual(result?.headerText, "Important Notice")
        XCTAssertEqual(result?.description, "Please review your settings.")
        XCTAssertEqual(result?.buttonText, "I understand")
        XCTAssertEqual(result?.organizationId, "organization-1")
        XCTAssertEqual(result?.revisionDate, revisionDate)
        XCTAssertTrue(result?.showAfterEveryLogin == true)
    }

    /// `getOrganizationUserNotificationBannerData()` returns `nil` optional fields and
    /// `showAfterEveryLogin` defaults to `false` when those fields are absent.
    func test_getOrganizationUserNotificationBannerData_validPolicy_minimalFields() async {
        configService.featureFlagsBool[.organizationUserNotificationBanner] = true
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success([
            .fixture(
                data: [PolicyOptionType.description.rawValue: .string("Minimal message.")],
                type: .organizationUserNotification,
            ),
        ])
        stubSdkFilterByType()

        let result = await subject.getOrganizationUserNotificationBannerData()
        XCTAssertNil(result?.headerText)
        XCTAssertEqual(result?.description, "Minimal message.")
        XCTAssertNil(result?.buttonText)
        XCTAssertFalse(result?.showAfterEveryLogin == true)
    }

    // MARK: - getRestrictedItemCipherTypes Tests

    /// `getRestrictedItemCipherTypes()` returns the restricted cipher types that apply to the user.
    func test_getRestrictedItemCipherTypes() async {
        let result: Policy = .fixture(type: .restrictItemTypes)
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success([result])
        stubSdkFilterByType()

        let restrictedTypes: [BitwardenShared.CipherType] = await subject.getRestrictedItemCipherTypes()
        XCTAssertEqual(restrictedTypes, [.card])
    }

    /// `getRestrictedItemCipherTypes()` returns the restricted cipher types that apply to the user when one
    /// organization has the policy enabled but not another.
    func test_getRestrictedItemCipherTypes_multipleOrganizations() async {
        let result: Policy = .fixture(enabled: true, organizationId: "org-2", type: .restrictItemTypes)
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture(id: "org-1"), .fixture(id: "org-2")])
        policyDataStore.fetchPoliciesNewResult = .success([
            .fixture(enabled: false, organizationId: "org-1", type: .twoFactorAuthentication),
            result,
        ])
        stubSdkFilterByType()

        let restrictedTypes = await subject.getRestrictedItemCipherTypes()
        XCTAssertEqual(restrictedTypes, [.card])
    }

    /// `getRestrictedItemCipherTypes()` returns empty array when there are no policies.
    func test_getRestrictedItemCipherTypes_noPolicies() async {
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        policyDataStore.fetchPoliciesNewResult = .success([])
        stubSdkFilterByType()

        let restrictedTypes = await subject.getRestrictedItemCipherTypes()
        XCTAssertTrue(restrictedTypes.isEmpty)
    }

    // MARK: - SDK boundary Tests

    /// `replacePoliciesNew(_:userId:)` updates the in-memory accepted-state policy cache so
    /// subsequent calls to `policyAppliesToUser(_:)` reflect the new policies.
    func test_replacePoliciesNew_updatesCache() async throws {
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture(id: "org-1")])

        // Initially no accepted-state policies → SDK isn't consulted and nothing applies.
        clientService.mockPolicies.filterByTypeReturnValue = []

        var policyApplies = await subject.policyAppliesToUser(.twoFactorAuthentication)
        XCTAssertFalse(policyApplies)

        // Replace accepted-state policies — this populates the in-memory cache
        try await subject.replacePoliciesNew(
            [.fixture(type: .twoFactorAuthentication)],
            userId: "1",
        )

        clientService.mockPolicies.filterByTypeReturnValue = [
            BitwardenSdk.PolicyView(
                id: "policy-1",
                organizationId: "org-1",
                type: .twoFactorAuthentication,
                data: nil,
                enabled: true,
                revisionDate: nil,
            ),
        ]

        policyApplies = await subject.policyAppliesToUser(.twoFactorAuthentication)
        XCTAssertTrue(policyApplies)
    }

    /// `policyAppliesToUser(_:)` delegates to `PoliciesClient.filterByType` and returns `true` when
    /// the SDK reports the policy applies.
    func test_policyAppliesToUser_filterByTypeCalled() async {
        stateService.activeAccount = .fixture()

        policyDataStore.fetchPoliciesNewResult = .success([.fixture(enabled: true, type: .masterPassword)])
        organizationService.fetchAllOrganizationsResult = .success([.fixture(id: "organization-1", status: .accepted)])

        // SDK returns the policy → applies
        clientService.mockPolicies.filterByTypeReturnValue = [
            BitwardenSdk.PolicyView(
                id: "policy-1",
                organizationId: "organization-1",
                type: .masterPassword,
                data: nil,
                enabled: true,
                revisionDate: nil,
            ),
        ]

        let applies = await subject.policyAppliesToUser(.masterPassword)

        XCTAssertTrue(applies)
        XCTAssertTrue(clientService.mockPolicies.filterByTypeCalled)
        XCTAssertEqual(clientService.mockPolicies.filterByTypeReceivedArguments?.policyType, .masterPassword)
    }

    /// `policyAppliesToUser(_:)` returns `false` when the SDK returns an empty list (policy does
    /// not apply to this user in their organization context).
    func test_policyAppliesToUser_sdkReturnsEmpty() async {
        stateService.activeAccount = .fixture()

        policyDataStore.fetchPoliciesNewResult = .success([.fixture(enabled: true, type: .masterPassword)])
        organizationService.fetchAllOrganizationsResult = .success([.fixture(type: .owner)])

        // SDK returns empty (e.g. owner is exempt)
        clientService.mockPolicies.filterByTypeReturnValue = []

        let applies = await subject.policyAppliesToUser(.masterPassword)

        XCTAssertFalse(applies)
        XCTAssertTrue(clientService.mockPolicies.filterByTypeCalled)
    }

    /// `policyAppliesToUser(_:)` hands the SDK a policy context for each organization, carrying the
    /// membership status, role, enabled state and policy capability the SDK filters on.
    func test_policyAppliesToUser_mapsOrganizationContexts() async {
        stateService.activeAccount = .fixture()

        policyDataStore.fetchPoliciesNewResult = .success([.fixture(enabled: true, type: .maximumVaultTimeout)])
        organizationService.fetchAllOrganizationsResult = .success([
            .fixture(
                enabled: false,
                id: "org-1",
                isProviderUser: true,
                status: .accepted,
                type: .owner,
                usePolicies: false,
            ),
            .fixture(
                enabled: true,
                id: "org-2",
                isProviderUser: false,
                status: .invited,
                type: .user,
                usePolicies: true,
            ),
        ])
        clientService.mockPolicies.filterByTypeReturnValue = []

        _ = await subject.policyAppliesToUser(.maximumVaultTimeout)

        let contexts = clientService.mockPolicies.filterByTypeReceivedArguments?.organizationUserPolicyContexts
        XCTAssertEqual(
            contexts,
            [
                BitwardenSdk.OrganizationUserPolicyContext(
                    id: "org-1",
                    status: .accepted,
                    role: .owner,
                    enabled: false,
                    usePolicies: false,
                    isProviderUser: true,
                ),
                BitwardenSdk.OrganizationUserPolicyContext(
                    id: "org-2",
                    status: .invited,
                    role: .user,
                    enabled: true,
                    usePolicies: true,
                    isProviderUser: false,
                ),
            ],
        )
    }

    /// `policyAppliesToUser(_:)` maps the staged membership status through to the SDK, which
    /// decides whether staged members are subject to the policy.
    func test_policyAppliesToUser_mapsStagedOrganizationContext() async {
        stateService.activeAccount = .fixture()

        policyDataStore.fetchPoliciesNewResult = .success([.fixture(enabled: true, type: .masterPassword)])
        organizationService.fetchAllOrganizationsResult = .success([.fixture(status: .staged)])
        clientService.mockPolicies.filterByTypeReturnValue = []

        _ = await subject.policyAppliesToUser(.masterPassword)

        let contexts = clientService.mockPolicies.filterByTypeReceivedArguments?.organizationUserPolicyContexts
        XCTAssertEqual(contexts?.first?.status, .staged)
    }

    /// `policyAppliesToUser(_:)` converts the stored policy into the SDK's `PolicyView`
    /// representation, encoding the policy's option data as JSON.
    func test_policyAppliesToUser_mapsPolicyToSdkPolicyView() async throws {
        stateService.activeAccount = .fixture()

        policyDataStore.fetchPoliciesNewResult = .success([maximumTimeoutPolicy])
        organizationService.fetchAllOrganizationsResult = .success([.fixture()])
        stubSdkFilterByType()

        _ = await subject.policyAppliesToUser(.maximumVaultTimeout)

        let sentPolicy = try XCTUnwrap(
            clientService.mockPolicies.filterByTypeReceivedArguments?.policies.first,
        )
        XCTAssertEqual(sentPolicy.id, maximumTimeoutPolicy.id)
        XCTAssertEqual(sentPolicy.organizationId, maximumTimeoutPolicy.organizationId)
        XCTAssertEqual(sentPolicy.type, .maximumVaultTimeout)
        XCTAssertTrue(sentPolicy.enabled)

        let encodedData = try XCTUnwrap(sentPolicy.data?.data(using: .utf8))
        let decodedData = try JSONDecoder().decode([String: AnyCodable].self, from: encodedData)
        XCTAssertEqual(decodedData[PolicyOptionType.minutes.rawValue]?.intValue, 60)
        XCTAssertEqual(decodedData[PolicyOptionType.action.rawValue]?.stringValue, "lock")
    }

    /// `policyAppliesToUser(_:)` returns `[]` (safe degradation) and reports the error when
    /// `clientService.policies` throws.
    func test_policyAppliesToUser_clientServiceThrowsReturnsEmpty() async {
        stateService.activeAccount = .fixture()

        policyDataStore.fetchPoliciesNewResult = .success([.fixture(enabled: true, type: .masterPassword)])
        organizationService.fetchAllOrganizationsResult = .success([.fixture(status: .accepted)])

        clientService.policiesError = BitwardenTestError.example

        let applies = await subject.policyAppliesToUser(.masterPassword)

        // Degraded to empty (not crashing)
        XCTAssertFalse(applies)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `getMasterPasswordPolicyOptions()` excludes policies without data before invoking the SDK,
    /// verifying the filter is forwarded to `sdkFilterPolicies`.
    func test_getMasterPasswordPolicyOptions_filterExcludesNilDataPolicy() async throws {
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([.fixture(id: "org-1", status: .accepted)])

        // Policy without data — the { $0.data != nil } filter should exclude it before the SDK call.
        policyDataStore.fetchPoliciesNewResult = .success([.fixture(type: .masterPassword)])

        let options = try await subject.getMasterPasswordPolicyOptions()

        XCTAssertNil(options)
        XCTAssertFalse(clientService.mockPolicies.filterByTypeCalled)
    }

    /// `getSendPolicyOptions()` enforces no Send restrictions when the SDK reports no applying
    /// policies.
    func test_getSendPolicyOptions_sdkNoApplyingPolicies() async {
        stateService.activeAccount = .fixture()
        configService.featureFlagsBool[.sendControls] = true
        organizationService.fetchAllOrganizationsResult = .success([.fixture(id: "org-1", status: .accepted)])
        policyDataStore.fetchPoliciesNewResult = .success([.fixture(type: .sendControls)])
        clientService.mockPolicies.filterByTypeReturnValue = []

        let options = await subject.getSendPolicyOptions()

        XCTAssertTrue(clientService.mockPolicies.filterByTypeCalled)
        XCTAssertFalse(options.isSendDisabled)
        XCTAssertFalse(options.isHideEmailDisabled)
        XCTAssertNil(options.enforcedAccessType)
    }

    /// `getSendPolicyOptions()` parses the Send restrictions from the policies the SDK reports as
    /// applying.
    func test_getSendPolicyOptions_sdkParsesApplyingPolicies() async {
        stateService.activeAccount = .fixture()
        configService.featureFlagsBool[.sendControls] = true
        organizationService.fetchAllOrganizationsResult = .success([.fixture(id: "org-1", status: .accepted)])
        policyDataStore.fetchPoliciesNewResult = .success([.fixture(type: .sendControls)])
        clientService.mockPolicies.filterByTypeReturnValue = [
            BitwardenSdk.PolicyView(
                id: "policy-1",
                organizationId: "org-1",
                type: .sendControls,
                data: #"{"disableSend": true, "disableHideEmail": true, "whoCanAccess": 2}"#,
                enabled: true,
                revisionDate: nil,
            ),
        ]

        let options = await subject.getSendPolicyOptions()

        XCTAssertTrue(clientService.mockPolicies.filterByTypeCalled)
        XCTAssertTrue(options.isSendDisabled)
        XCTAssertTrue(options.isHideEmailDisabled)
        XCTAssertEqual(options.enforcedAccessType, .specificPeople)
    }
} // swiftlint:disable:this file_length
