import Combine
import Foundation

@testable import BitwardenShared

class MockUserVerificationHelper: UserVerificationHelper {
    var userVerificationDelegate: (any BitwardenShared.UserVerificationDelegate)?

    var canVerifyDeviceLocalAuthResult: Bool = false
    var setupPinCalled = false
    var verifyDeviceLocalAuthBecauseValue: String?
    var verifyDeviceLocalAuthCalled: Bool = false
    var verifyDeviceLocalAuthResult: Result<BitwardenShared.UserVerificationResult, Error> = .success(.verified)
    var verifyMasterPasswordCalled: Bool = false
    var verifyMasterPasswordResult: Result<BitwardenShared.UserVerificationResult, Error> = .success(.verified)
    var verifyPinCalled: Bool = false
    var verifyPinResult: Result<BitwardenShared.UserVerificationResult, Error> = .success(.verified)

    func canVerifyDeviceLocalAuth() -> Bool {
        canVerifyDeviceLocalAuthResult
    }

    func setupPin() async throws {
        setupPinCalled = true
    }

    func verifyDeviceLocalAuth(reason: String) async throws -> UserVerificationResult {
        verifyDeviceLocalAuthCalled = true
        verifyDeviceLocalAuthBecauseValue = reason
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
