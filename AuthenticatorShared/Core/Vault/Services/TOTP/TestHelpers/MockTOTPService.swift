@testable import AuthenticatorShared

class MockTOTPService: TOTPService {
    var refreshTOTPCodeResult: Result<TOTPCodeModel, Error> = .success(
        TOTPCodeModel(code: .base32Key, codeGenerationDate: .now, period: 30)
    )
    var refreshedTOTPKeyConfig: TOTPKeyModel?

    var capturedKey: String?
    var getTOTPConfigResult: Result<TOTPKeyModel, Error> = .failure(TOTPServiceError.invalidKeyFormat)

    func getTotpCode(for key: TOTPKeyModel) async throws -> TOTPCodeModel {
        refreshedTOTPKeyConfig = key
        return try refreshTOTPCodeResult.get()
    }

    func getTOTPConfiguration(key: String?) throws -> TOTPKeyModel {
        capturedKey = key
        return try getTOTPConfigResult.get()
    }
}
