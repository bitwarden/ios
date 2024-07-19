@testable import BitwardenShared

class MockTOTPService: TOTPService {
    var capturedKey: String?
    var getTOTPConfigResult: Result<TOTPKeyModel, Error> = .failure(TOTPServiceError.invalidKeyFormat)

    func getTOTPConfiguration(key: String) -> BitwardenShared.TOTPKeyModel {
        capturedKey = key
        return TOTPKeyModel(authenticatorKey: key)
    }
}
