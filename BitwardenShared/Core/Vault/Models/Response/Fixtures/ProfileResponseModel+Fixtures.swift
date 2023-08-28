import Foundation

@testable import BitwardenShared

extension ProfileResponseModel {
    static func fixture(
        avatarColor: String? = nil,
        culture: String? = nil,
        email: String? = nil,
        emailVerified: Bool = false,
        forcePasswordReset: Bool = false,
        id: String = UUID().uuidString,
        key: String? = nil,
        masterPasswordHint: String? = nil, // swiftlint:disable:this inclusive_language
        name: String? = nil,
        object: String? = nil,
        organizations: [ProfileOrganizationResponseModel]? = nil,
        premium: Bool = false,
        premiumFromOrganization: Bool = false,
        privateKey: String? = nil,
        securityStamp: String? = nil,
        twoFactorEnabled: Bool = false,
        usesKeyConnector: Bool = false
    ) -> ProfileResponseModel {
        self.init(
            avatarColor: avatarColor,
            culture: culture,
            email: email,
            emailVerified: emailVerified,
            forcePasswordReset: forcePasswordReset,
            id: id,
            key: key,
            masterPasswordHint: masterPasswordHint,
            name: name,
            object: object,
            organizations: organizations,
            premium: premium,
            premiumFromOrganization: premiumFromOrganization,
            privateKey: privateKey,
            securityStamp: securityStamp,
            twoFactorEnabled: twoFactorEnabled,
            usesKeyConnector: usesKeyConnector
        )
    }
}
