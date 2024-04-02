@testable import AuthenticatorShared

class MockTOTPService: TOTPService {
    var capturedKey: String?
    var getTOTPConfigResult: Result<TOTPKeyModel, Error> = .failure(TOTPServiceError.invalidKeyFormat)

    func getTOTPConfiguration(key: String?) throws -> AuthenticatorShared.TOTPKeyModel {
        capturedKey = key
        return try getTOTPConfigResult.get()
    }
}
