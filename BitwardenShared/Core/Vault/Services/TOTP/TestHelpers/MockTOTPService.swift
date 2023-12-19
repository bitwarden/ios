@testable import BitwardenShared

class MockTOTPService: TOTPService {
    var capturedKey: String?
    var getTOTPConfigResult: Result<TOTPCodeConfig, Error> = .failure(TOTPServiceError.invalidKeyFormat)

    func getTOTPConfiguration(key: String) throws -> BitwardenShared.TOTPCodeConfig {
        capturedKey = key
        return try getTOTPConfigResult.get()
    }
}
