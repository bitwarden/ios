// swiftlint:disable:this file_name

import BitwardenKit
import BitwardenSdk
import Foundation

// MARK: - Policy ↔ SDK Policy

extension BitwardenSdk.Policy {
    /// Converts an iOS `Policy` to a `BitwardenSdk.Policy`.
    ///
    init(_ policy: BitwardenShared.Policy) {
        let dataJson: String? = policy.data.flatMap { dict in
            (try? JSONEncoder().encode(dict)).flatMap { String(data: $0, encoding: .utf8) }
        }

        self.init(
            id: policy.id,
            organizationId: policy.organizationId,
            type: BitwardenSdk.PolicyType(policy.type),
            data: dataJson,
            enabled: policy.enabled,
            revisionDate: policy.revisionDate,
        )
    }
}

extension BitwardenShared.Policy {
    /// Converts a `BitwardenSdk.Policy` to an iOS `Policy`.
    ///
    /// Returns `nil` when the SDK policy type has no iOS equivalent.
    ///
    init?(_ sdkPolicy: BitwardenSdk.Policy) {
        guard let type = PolicyType(sdkPolicy.type) else { return nil }

        let decodedData: [String: AnyCodable]? = sdkPolicy.data
            .flatMap { $0.data(using: .utf8) }
            .flatMap { try? JSONDecoder().decode([String: AnyCodable].self, from: $0) }

        self.init(
            data: decodedData,
            enabled: sdkPolicy.enabled,
            id: sdkPolicy.id,
            organizationId: sdkPolicy.organizationId,
            revisionDate: sdkPolicy.revisionDate,
            type: type,
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
    init(_ type: PolicyType) {
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
        case .sendControls: self = .sendControls
        case .sendOptions: self = .sendOptions
        case .twoFactorAuthentication: self = .twoFactorAuthentication
        }
    }
}

extension PolicyType {
    /// Converts an SDK `BitwardenSdk.PolicyType` to the iOS `PolicyType`.
    ///
    /// Returns `nil` for SDK-only cases with no iOS equivalent.
    ///
    init?(_ sdkType: BitwardenSdk.PolicyType) {
        switch sdkType {
        case .activateAutofill: self = .activateAutofill
        case .disablePersonalVaultExport: self = .disablePersonalVaultExport
        case .disableSend: self = .disableSend
        case .masterPassword: self = .masterPassword
        case .maximumVaultTimeout: self = .maximumVaultTimeout
        case .organizationDataOwnership: self = .personalOwnership
        case .organizationUserNotification: self = .organizationUserNotification
        case .passwordGenerator: self = .passwordGenerator
        case .removeUnlockWithPin: self = .removeUnlockWithPin
        case .requireSso: self = .requireSSO
        case .resetPassword: self = .resetPassword
        case .restrictedItemTypes: self = .restrictItemTypes
        case .sendControls: self = .sendControls
        case .sendOptions: self = .sendOptions
        case .singleOrg: self = .onlyOrg
        case .twoFactorAuthentication: self = .twoFactorAuthentication
        case .automaticAppLogIn,
             .automaticUserConfirmation,
             .autotypeDefaultSetting,
             .blockClaimedDomainAccountCreation,
             .fillAssist,
             .freeFamiliesSponsorship,
             .uriMatchDefaults: return nil
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
        case .staged: self = .staged
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
