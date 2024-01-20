import Foundation

@testable import BitwardenShared

extension LoginRequest {
    static func fixture(
        creationDate: Date = Date(year: 3000, month: 1, day: 1),
        fingerprintPhrase: String? = nil,
        id: String = "1",
        key: String? = "reallyLongKey",
        masterPasswordHash: String? = "reallyLongMasterPasswordHash",
        origin: String = "vault.bitwarden.com",
        publicKey: String = "reallyLongPublicKey",
        requestAccessCode: String? = nil,
        requestApproved: Bool? = nil,
        requestDeviceType: String = "iOS",
        requestIpAddress: String = "11.22.333.444",
        responseDate: Date? = nil
    ) -> LoginRequest {
        LoginRequest(
            creationDate: creationDate,
            fingerprintPhrase: fingerprintPhrase,
            id: id,
            key: key,
            origin: origin,
            publicKey: publicKey,
            requestAccessCode: requestAccessCode,
            requestApproved: requestApproved,
            requestDeviceType: requestDeviceType,
            requestIpAddress: requestIpAddress,
            responseDate: responseDate,
            masterPasswordHash: masterPasswordHash
        )
    }
}
