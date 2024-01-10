@testable import BitwardenShared

class MockTOTPService: TOTPService {
    var capturedKey: String?
    var getTOTPConfigResult: Result<TOTPKeyModel, Error> = .failure(TOTPServiceError.invalidKeyFormat)

    func getTOTPConfiguration(key: String) throws -> BitwardenShared.TOTPKeyModel {
        capturedKey = key
        return try getTOTPConfigResult.get()
    }
}
