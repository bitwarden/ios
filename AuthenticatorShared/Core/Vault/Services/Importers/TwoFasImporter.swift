import Foundation

class TwoFasImporter {
    static func importItems(data: Data) throws -> [AuthenticatorItemView] {
        let decoder = JSONDecoder()
        let vault = try decoder.decode(TwoFasVault.self, from: data)
        return vault.services.compactMap { service in
            switch service.otp.tokenType {
            case "TOTP":
                let otp = OTPAuthModel(
                    accountName: service.otp.account,
                    algorithm: TOTPCryptoHashAlgorithm(from: service.otp.algorithm),
                    digits: service.otp.digits ?? 6,
                    issuer: service.otp.issuer ?? service.name,
                    period: service.otp.period ?? 30,
                    secret: service.secret
                )
                return AuthenticatorItemView(
                    favorite: false,
                    id: UUID().uuidString,
                    name: service.name,
                    totpKey: otp.otpAuthUri,
                    username: service.otp.account
                )
            case "STEAM":
                return AuthenticatorItemView(
                    favorite: false,
                    id: UUID().uuidString,
                    name: service.name,
                    totpKey: "steam://\(service.secret)",
                    username: service.otp.account
                )
            default:
                return nil
            }
        }
    }
}

struct TwoFasVault: Codable {
    let services: [TwoFasService]
}

struct TwoFasService: Codable {
    let otp: TwoFasOtp
    let name: String
    let secret: String
}

struct TwoFasOtp: Codable {
    let account: String?
    let algorithm: String?
    let digits: Int?
    let issuer: String?
    let period: Int?
    let tokenType: String?
}
