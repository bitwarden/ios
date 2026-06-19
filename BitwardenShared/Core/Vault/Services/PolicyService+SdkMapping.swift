// swiftlint:disable:this file_name

import BitwardenKit
import BitwardenSdk
import Foundation

// MARK: - Policy ↔ SDK PolicyView

extension BitwardenSdk.PolicyView {
    /// Converts an iOS `Policy` to a `BitwardenSdk.PolicyView`.
    ///
    /// Returns `nil` when the iOS policy type has no SDK equivalent (e.g., `.unknown`).
    ///
    init?(_ policy: Policy) {
        guard let sdkType = BitwardenSdk.PolicyType(policy.type) else { return nil }

        let dataJson: String? = policy.data.flatMap { dict in
            (try? JSONEncoder().encode(dict)).flatMap { String(data: $0, encoding: .utf8) }
        }

        self.init(
            id: policy.id,
            organizationId: policy.organizationId,
            type: sdkType,
            data: dataJson,
            enabled: policy.enabled,
            revisionDate: policy.revisionDate,
        )
    }
}

extension Policy {
    /// Converts a `BitwardenSdk.PolicyView` to an iOS `Policy`.
    ///
    init(_ policyView: BitwardenSdk.PolicyView) {
        let decodedData: [String: AnyCodable]? = policyView.data
            .flatMap { $0.data(using: .utf8) }
            .flatMap { try? JSONDecoder().decode([String: AnyCodable].self, from: $0) }

        self.init(
            data: decodedData,
            enabled: policyView.enabled,
            id: policyView.id,
            organizationId: policyView.organizationId,
            revisionDate: policyView.revisionDate,
            type: PolicyType(policyView.type),
        )
    }
}

// MARK: - Organization → SDK OrganizationUserPolicyContext

extension BitwardenSdk.OrganizationUserPolicyContext {
    /// Converts an iOS `Organization` to a `BitwardenSdk.OrganizationUserPolicyContext`.
    ///
    init(_ organization: Organization) {
        self.init(
            id: organization.id,
            status: BitwardenSdk.OrganizationUserStatusType(organization.status),
            role: BitwardenSdk.OrganizationUserType(organization.type),
            enabled: organization.enabled,
            usePolicies: organization.usePolicies,
            isProviderUser: organization.isProviderUser,
        )
    }
}

// MARK: - PolicyType mapping (iOS ↔ SDK)

extension BitwardenSdk.PolicyType {
    /// Converts an iOS `PolicyType` to the SDK's `BitwardenSdk.PolicyType`.
    ///
    /// Returns `nil` for iOS-only cases (e.g., `.unknown`) with no SDK equivalent.
    ///
    init?(_ type: PolicyType) {
        switch type {
        case .activateAutofill: self = .activateAutofill
        case .disablePersonalVaultExport: self = .disablePersonalVaultExport
        case .disableSend: self = .disableSend
        case .masterPassword: self = .masterPassword
        case .maximumVaultTimeout: self = .maximumVaultTimeout
        case .onlyOrg: self = .singleOrg
        case .organizationUserNotification: self = .organizationUserNotification
        case .passwordGenerator: self = .passwordGenerator
        case .personalOwnership: self = .organizationDataOwnership
        case .removeUnlockWithPin: self = .removeUnlockWithPin
        case .requireSSO: self = .requireSso
        case .resetPassword: self = .resetPassword
        case .restrictItemTypes: self = .restrictedItemTypes
        case .sendOptions: self = .sendOptions
        case .twoFactorAuthentication: self = .twoFactorAuthentication
        case .unknown: return nil
        }
    }
}

extension PolicyType {
    /// Converts an SDK `BitwardenSdk.PolicyType` to the iOS `PolicyType`.
    ///
    /// SDK-only cases (e.g., `sendControls`) with no iOS equivalent map to `.unknown`.
    ///
    init(_ sdkType: BitwardenSdk.PolicyType) {
        switch sdkType {
        case .activateAutofill: self = .activateAutofill
        case .disablePersonalVaultExport: self = .disablePersonalVaultExport
        case .disableSend: self = .disableSend
        case .masterPassword: self = .masterPassword
        case .maximumVaultTimeout: self = .maximumVaultTimeout
        case .organizationDataOwnership: self = .personalOwnership
        case .passwordGenerator: self = .passwordGenerator
        case .removeUnlockWithPin: self = .removeUnlockWithPin
        case .requireSso: self = .requireSSO
        case .resetPassword: self = .resetPassword
        case .restrictedItemTypes: self = .restrictItemTypes
        case .sendOptions: self = .sendOptions
        case .singleOrg: self = .onlyOrg
        case .twoFactorAuthentication: self = .twoFactorAuthentication
        case .automaticAppLogIn,
             .automaticUserConfirmation,
             .autotypeDefaultSetting,
             .blockClaimedDomainAccountCreation,
             .freeFamiliesSponsorship,
             .organizationUserNotification,
             .sendControls,
             .uriMatchDefaults: self = .unknown
        }
    }
}

// MARK: - OrganizationUserStatusType mapping (iOS ↔ SDK)

extension BitwardenSdk.OrganizationUserStatusType {
    /// Converts an iOS `OrganizationUserStatusType` to the SDK equivalent.
    ///
    init(_ status: OrganizationUserStatusType) {
        switch status {
        case .accepted: self = .accepted
        case .confirmed: self = .confirmed
        case .invited: self = .invited
        }
    }
}

// MARK: - OrganizationUserType mapping (iOS ↔ SDK)

extension BitwardenSdk.OrganizationUserType {
    /// Converts an iOS `OrganizationUserType` to the SDK equivalent.
    ///
    init(_ type: OrganizationUserType) {
        switch type {
        case .admin: self = .admin
        case .custom: self = .custom
        case .owner: self = .owner
        case .user: self = .user
        }
    }
}
