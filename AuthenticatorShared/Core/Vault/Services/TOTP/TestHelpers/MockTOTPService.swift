import Foundation

@testable import AuthenticatorShared

class MockTOTPService: TOTPService {
    var getTotpCodeResult: Result<TOTPCodeModel, Error> = .success(
        TOTPCodeModel(code: "123456", codeGenerationDate: .now, period: 30)
    )
    var getTotpCodeConfig: TOTPKeyModel?

    var capturedKey: String?
    var getTOTPConfigResult: Result<TOTPKeyModel, Error> = .failure(TOTPServiceError.invalidKeyFormat)

    func getTotpCode(for key: TOTPKeyModel) async throws -> TOTPCodeModel {
        getTotpCodeConfig = key
        return try getTotpCodeResult.get()
    }

    func getTOTPConfiguration(key: String?) throws -> TOTPKeyModel {
        capturedKey = key
        return try getTOTPConfigResult.get()
    }
}
