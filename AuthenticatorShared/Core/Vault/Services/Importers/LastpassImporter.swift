import Foundation

class LastpassImporter {
    static func importItems(data: Data) throws -> [AuthenticatorItemView] {
        let decoder = JSONDecoder()
        let vault = try decoder.decode(LastpassVault.self, from: data)
        return vault.accounts.compactMap { account in
            let otp = OTPAuthModel(
                accountName: account.userName.nilIfEmpty,
                algorithm: TOTPCryptoHashAlgorithm(rawValue: account.algorithm) ?? .sha1,
                digits: account.digits,
                issuer: account.issuerName.nilIfEmpty,
                period: account.timeStep,
                secret: account.secret
            )
            return AuthenticatorItemView(
                favorite: account.isFavorite,
                id: UUID().uuidString,
                name: account.issuerName,
                totpKey: otp.otpAuthUri,
                username: account.userName.nilIfEmpty
            )
        }
    }
}

struct LastpassVault: Codable {
    let accounts: [LastpassAccount]
}

struct LastpassAccount: Codable {
    let algorithm: String
    let digits: Int
    let isFavorite: Bool
    let issuerName: String
    let secret: String
    let timeStep: Int
    let userName: String
}
