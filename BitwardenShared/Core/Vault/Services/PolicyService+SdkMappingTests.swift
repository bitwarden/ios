// swiftlint:disable:this file_name

import BitwardenSdk
import Foundation
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

struct PolicySdkMappingTests {
    // MARK: Tests

    /// `BitwardenShared.Policy.init(_:)` converts an SDK policy to an iOS policy.
    @Test
    func policy_initFromSdkPolicy() {
        let sdkPolicy = BitwardenSdk.Policy(
            id: "policy-1",
            organizationId: "org-1",
            type: .organizationUserNotification,
            data: #"{"description":"Hello"}"#,
            enabled: true,
            revisionDate: nil,
        )

        let subject = BitwardenShared.Policy(sdkPolicy)

        #expect(subject == .fixture(
            data: ["description": .string("Hello")],
            organizationId: "org-1",
            type: .organizationUserNotification,
        ))
    }

    /// `BitwardenShared.Policy.init(_:)` returns `nil` for an SDK policy type with no iOS equivalent.
    @Test
    func policy_initFromSdkPolicy_sdkOnlyType() {
        let sdkPolicy = BitwardenSdk.Policy(
            id: "policy-1",
            organizationId: "org-1",
            type: .fillAssist,
            data: nil,
            enabled: true,
            revisionDate: nil,
        )

        #expect(BitwardenShared.Policy(sdkPolicy) == nil)
    }

    /// `PolicyType.init(_:)` round-trips every iOS policy type through the SDK policy type.
    @Test
    func policyType_roundTrip() {
        let allTypes: [BitwardenShared.PolicyType] = [
            .twoFactorAuthentication, .masterPassword, .passwordGenerator, .onlyOrg, .requireSSO,
            .personalOwnership, .disableSend, .sendOptions, .resetPassword, .maximumVaultTimeout,
            .disablePersonalVaultExport, .activateAutofill, .removeUnlockWithPin, .restrictItemTypes,
            .organizationUserNotification, .sendControls,
        ]
        for type in allTypes {
            #expect(BitwardenShared.PolicyType(BitwardenSdk.PolicyType(type)) == type)
        }
    }

    /// `PolicyType.init(_:)` maps the SDK's `organizationUserNotification` to the iOS case.
    @Test
    func policyType_initFromSdk_organizationUserNotification() {
        let subject = BitwardenShared.PolicyType(BitwardenSdk.PolicyType.organizationUserNotification)
        #expect(subject == .organizationUserNotification)
    }

    /// `PolicyType.init(_:)` returns `nil` for SDK-only policy types.
    @Test
    func policyType_initFromSdk_sdkOnlyTypes() {
        let sdkOnlyTypes: [BitwardenSdk.PolicyType] = [
            .automaticAppLogIn, .automaticUserConfirmation, .autotypeDefaultSetting,
            .blockClaimedDomainAccountCreation, .fillAssist, .freeFamiliesSponsorship, .uriMatchDefaults,
        ]
        for sdkType in sdkOnlyTypes {
            #expect(BitwardenShared.PolicyType(sdkType) == nil)
        }
    }

    /// `BitwardenSdk.Policy.init(_:)` converts an iOS policy to an SDK policy.
    @Test
    func sdkPolicy_initFromPolicy() {
        let subject = BitwardenSdk.Policy(.fixture(id: "policy-1", organizationId: "org-1", type: .onlyOrg))

        #expect(subject.id == "policy-1")
        #expect(subject.organizationId == "org-1")
        #expect(subject.type == .singleOrg)
        #expect(subject.enabled)
        #expect(subject.data == nil)
    }
}
