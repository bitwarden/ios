import Combine
import Foundation

@testable import BitwardenShared

class MockUserVerificationHelper: UserVerificationHelper {
    var verifyDeviceLocalAuthBecauseValue: String?
    var verifyDeviceLocalAuthCalled: Bool = false
    var verifyDeviceLocalAuthResult: Result<BitwardenShared.UserVerificationResult, Error> = .success(.verified)
    var verifyMasterPasswordCalled: Bool = false
    var verifyMasterPasswordResult: Result<BitwardenShared.UserVerificationResult, Error> = .success(.verified)
    var verifyPinCalled: Bool = false
    var verifyPinResult: Result<BitwardenShared.UserVerificationResult, Error> = .success(.verified)

    func verifyDeviceLocalAuth(because: String) async throws -> UserVerificationResult {
        verifyDeviceLocalAuthCalled = true
        verifyDeviceLocalAuthBecauseValue = because
        return try verifyDeviceLocalAuthResult.get()
    }

    func verifyMasterPassword() async throws -> BitwardenShared.UserVerificationResult {
        verifyMasterPasswordCalled = true
        return try verifyMasterPasswordResult.get()
    }

    func verifyPin() async throws -> BitwardenShared.UserVerificationResult {
        verifyPinCalled = true
        return try verifyPinResult.get()
    }
}
