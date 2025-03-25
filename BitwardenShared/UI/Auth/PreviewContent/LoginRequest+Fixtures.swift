import Foundation

#if DEBUG
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
            masterPasswordHash: masterPasswordHash,
            origin: origin,
            publicKey: publicKey,
            requestAccessCode: requestAccessCode,
            requestApproved: requestApproved,
            requestDeviceType: requestDeviceType,
            requestIpAddress: requestIpAddress,
            responseDate: responseDate
        )
    }
}

fileprivate extension Date {
    init(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0,
        second: Int = 0,
        nanosecond: Int = 0,
        timeZone: TimeZone = TimeZone(secondsFromGMT: 0)!
    ) {
        let calendar = Calendar(identifier: .gregorian)
        let dateComponents = DateComponents(
            calendar: calendar,
            timeZone: timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second,
            nanosecond: nanosecond
        )
        self = dateComponents.date!
    }
}
#endif
