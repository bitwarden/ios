import Foundation

@testable import TestHarnessShared

extension StoredPasskeyCredential {
    static func fixture(
        rpId: String = "bitwarden.com",
        userName: String = "user",
        displayName: String = "User",
        credentialId: Data = Data([0x01, 0x02, 0x03]),
        publicKeyX963: Data = Data(repeating: 0x04, count: 65),
        createdAt: Date = Date(timeIntervalSince1970: 0),
    ) -> StoredPasskeyCredential {
        StoredPasskeyCredential(
            createdAt: createdAt,
            credentialId: credentialId,
            displayName: displayName,
            publicKeyX963: publicKeyX963,
            rpId: rpId,
            userName: userName,
        )
    }
}
