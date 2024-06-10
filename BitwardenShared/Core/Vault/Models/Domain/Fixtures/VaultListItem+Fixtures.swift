import BitwardenSdk
import Foundation

@testable import BitwardenShared

extension VaultListItem {
    static func fixture(
        cipherView: CipherView = .fixture()
    ) -> VaultListItem {
        VaultListItem(cipherView: cipherView)!
    }

    static func fixture(
        cipherView: CipherView = .fixture(),
        asFido2Credential: Bool
    ) -> VaultListItem {
        VaultListItem(cipherView: cipherView, asFido2Credential: asFido2Credential)!
    }

    static func fixtureGroup(
        id: String = "123",
        group: VaultListGroup = .card,
        count: Int = 1
    ) -> VaultListItem {
        VaultListItem(
            id: id,
            itemType: .group(
                group,
                count
            )
        )
    }

    static func fixtureTOTP(
        name: String = "Name",
        totp: VaultListTOTP
    ) -> VaultListItem {
        VaultListItem(
            id: totp.id,
            itemType: .totp(
                name: name,
                totpModel: totp
            )
        )
    }
}

extension VaultListTOTP {
    static func fixture(
        id: String = "123",
        loginView: BitwardenSdk.LoginView = .fixture(
            totp: .base32Key
        ),
        requiresMasterPassword: Bool = false,
        timeProvider: TimeProvider,
        totpCode: String = "123456",
        totpPeriod: UInt32 = 30
    ) -> VaultListTOTP {
        VaultListTOTP(
            id: id,
            loginView: loginView,
            requiresMasterPassword: requiresMasterPassword,
            totpCode: .init(
                code: totpCode,
                codeGenerationDate: timeProvider.presentTime,
                period: totpPeriod
            )
        )
    }

    static func fixture(
        id: String = "123",
        loginView: BitwardenSdk.LoginView = .fixture(
            totp: .base32Key
        ),
        requiresMasterPassword: Bool = false,
        totpCode: TOTPCodeModel = .init(
            code: "123456",
            codeGenerationDate: Date(),
            period: 30
        )
    ) -> VaultListTOTP {
        VaultListTOTP(
            id: id,
            loginView: loginView,
            requiresMasterPassword: requiresMasterPassword,
            totpCode: totpCode
        )
    }
}
