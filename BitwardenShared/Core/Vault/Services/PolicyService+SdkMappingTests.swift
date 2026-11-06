// swiftlint:disable:this file_name

import BitwardenSdk
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - PolicyServiceSdkMappingTests

struct PolicyServiceSdkMappingTests {
    // MARK: Properties

    /// Every iOS `PolicyType` (except `.unknown`) paired with its SDK equivalent.
    static let policyTypePairs: [(BitwardenShared.PolicyType, BitwardenSdk.PolicyType)] = [
        (.twoFactorAuthentication, .twoFactorAuthentication),
        (.masterPassword, .masterPassword),
        (.passwordGenerator, .passwordGenerator),
        (.onlyOrg, .singleOrg),
        (.requireSSO, .requireSso),
        (.personalOwnership, .organizationDataOwnership),
        (.disableSend, .disableSend),
        (.sendOptions, .sendOptions),
        (.resetPassword, .resetPassword),
        (.maximumVaultTimeout, .maximumVaultTimeout),
        (.disablePersonalVaultExport, .disablePersonalVaultExport),
        (.activateAutofill, .activateAutofill),
        (.automaticAppLogIn, .automaticAppLogIn),
        (.freeFamiliesSponsorship, .freeFamiliesSponsorship),
        (.removeUnlockWithPin, .removeUnlockWithPin),
        (.restrictItemTypes, .restrictedItemTypes),
        (.uriMatchDefaults, .uriMatchDefaults),
        (.autotypeDefaultSetting, .autotypeDefaultSetting),
        (.automaticUserConfirmation, .automaticUserConfirmation),
        (.blockClaimedDomainAccountCreation, .blockClaimedDomainAccountCreation),
        (.organizationUserNotification, .organizationUserNotification),
        (.sendControls, .sendControls),
        (.fillAssist, .fillAssist),
        (.autotypeGaPolicy, .autotypeGaPolicy),
    ]

    // MARK: Tests - PolicyType

    /// `BitwardenSdk.PolicyType.init(_:)` maps each iOS policy type to its SDK equivalent, with
    /// matching raw values.
    @Test(arguments: policyTypePairs)
    func sdkPolicyType_init(iosType: BitwardenShared.PolicyType, sdkType: BitwardenSdk.PolicyType) {
        let convertedType = BitwardenSdk.PolicyType(iosType)
        #expect(convertedType == sdkType)
        #expect(iosType.rawValue == Int(sdkType.rawValue))
    }

    /// `PolicyType.init(_:)` maps each SDK policy type to its iOS equivalent.
    @Test(arguments: policyTypePairs)
    func policyType_init(iosType: BitwardenShared.PolicyType, sdkType: BitwardenSdk.PolicyType) {
        let convertedType = BitwardenShared.PolicyType(sdkType)
        #expect(convertedType == iosType)
    }

    // MARK: Tests - Policy

    /// `BitwardenSdk.Policy.init(_:)` returns `nil` for a policy with an unknown type.
    @Test
    func sdkPolicy_init_unknown() {
        let sdkPolicy = BitwardenSdk.Policy(BitwardenShared.Policy.fixture(type: .unknown))
        #expect(sdkPolicy == nil)
    }
}
