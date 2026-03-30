import BitwardenKit
import BitwardenSdk

@testable import BitwardenShared

class MockTOTPService: TOTPService {
    var capturedKey: String?
    var copyTotpIfPossibleCalled = false
    var copyTotpIfPossibleError: Error?
    var getTOTPConfigResult: Result<TOTPKeyModel, Error> = .failure(TOTPKeyError.invalidKeyFormat)
    var isTotpAuthorizedResult = true

    func copyTotpIfPossible(cipher: BitwardenSdk.CipherView) async throws {
        copyTotpIfPossibleCalled = true
        if let copyTotpIfPossibleError {
            throw copyTotpIfPossibleError
        }
    }

    func getTOTPConfiguration(key: String?) throws -> BitwardenShared.TOTPKeyModel {
        capturedKey = key
        return try getTOTPConfigResult.get()
    }

    func isTotpAuthorized(for cipher: BitwardenSdk.CipherView) async -> Bool {
        isTotpAuthorizedResult
    }
}
