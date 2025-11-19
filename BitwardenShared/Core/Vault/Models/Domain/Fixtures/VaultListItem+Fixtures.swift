import BitwardenKit
import BitwardenSdk
import Foundation

@testable import BitwardenShared

extension VaultListItem {
    static func fixture(
        cipherListView: CipherListView = .fixture(),
    ) -> VaultListItem {
        VaultListItem(cipherListView: cipherListView)!
    }

    static func fixture(
        cipherListView: CipherListView = .fixture(),
        fido2CredentialAutofillView: Fido2CredentialAutofillView,
    ) -> VaultListItem {
        VaultListItem(cipherListView: cipherListView, fido2CredentialAutofillView: fido2CredentialAutofillView)!
    }

    static func fixtureGroup(
        id: String = "123",
        group: VaultListGroup = .card,
        count: Int = 1,
    ) -> VaultListItem {
        VaultListItem(
            id: id,
            itemType: .group(
                group,
                count,
            ),
        )
    }

    static func fixtureTOTP(
        name: String = "Name",
        totp: VaultListTOTP,
    ) -> VaultListItem {
        VaultListItem(
            id: totp.id,
            itemType: .totp(
                name: name,
                totpModel: totp,
            ),
        )
    }
}

extension VaultListTOTP {
    static func fixture(
        id: String = "123",
        loginListView: BitwardenSdk.LoginListView = .fixture(
            totp: .standardTotpKey,
        ),
        requiresMasterPassword: Bool = false,
        timeProvider: TimeProvider,
        totpCode: String = "123456",
        totpPeriod: UInt32 = 30,
    ) -> VaultListTOTP {
        VaultListTOTP(
            id: id,
            cipherListView: .fixture(type: .login(loginListView)),
            requiresMasterPassword: requiresMasterPassword,
            totpCode: .init(
                code: totpCode,
                codeGenerationDate: timeProvider.presentTime,
                period: totpPeriod,
            ),
        )
    }

    static func fixture(
        id: String = "123",
        loginListView: BitwardenSdk.LoginListView = .fixture(
            totp: .standardTotpKey,
        ),
        requiresMasterPassword: Bool = false,
        totpCode: TOTPCodeModel = .init(
            code: "123456",
            codeGenerationDate: Date(),
            period: 30,
        ),
    ) -> VaultListTOTP {
        VaultListTOTP(
            id: id,
            cipherListView: .fixture(type: .login(loginListView)),
            requiresMasterPassword: requiresMasterPassword,
            totpCode: totpCode,
        )
    }

    static func fixture(
        id: String = "123",
        cipherListView: CipherListView,
        requiresMasterPassword: Bool = false,
        totpCode: TOTPCodeModel = .init(
            code: "123456",
            codeGenerationDate: Date(),
            period: 30,
        ),
    ) -> VaultListTOTP {
        VaultListTOTP(
            id: id,
            cipherListView: cipherListView,
            requiresMasterPassword: requiresMasterPassword,
            totpCode: totpCode,
        )
    }
}
