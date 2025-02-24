import Foundation

class RaivoImporter {
    static func importItems(data: Data) throws -> [AuthenticatorItemView] {
        let decoder = JSONDecoder()
        let items = try decoder.decode([RavioItem].self, from: data)
        return items.map { item in
            let otp = OTPAuthModel(
                accountName: item.account.nilIfEmpty,
                algorithm: TOTPCryptoHashAlgorithm(rawValue: item.algorithm) ?? .sha1,
                digits: Int(item.digits) ?? 6,
                issuer: item.issuer.nilIfEmpty,
                period: Int(item.timer) ?? 30,
                secret: item.secret
            )
            return AuthenticatorItemView(
                favorite: Bool(item.pinned) ?? false,
                id: UUID().uuidString,
                name: item.issuer,
                totpKey: otp.otpAuthUri,
                username: item.account.nilIfEmpty
            )
        }
    }
}

struct RavioItem: Codable {
    let algorithm: String
    let account: String
    let digits: String
    let issuer: String
    let kind: String
    let pinned: String
    let secret: String
    let timer: String
}
