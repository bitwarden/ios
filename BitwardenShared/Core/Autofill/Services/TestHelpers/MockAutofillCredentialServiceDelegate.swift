@testable import BitwardenShared

class MockAutofillCredentialServiceDelegate: AutofillCredentialServiceDelegate {
    var unlockVaultWithNeverlockKeyCalled = false
    var unlockVaultWithNeverlockKeyError: Error?
    var unlockVaultWithNaverlockHandler: (() -> Void)?

    func unlockVaultWithNeverlockKey() async throws {
        unlockVaultWithNeverlockKeyCalled = true
        unlockVaultWithNaverlockHandler?()
        if let unlockVaultWithNeverlockKeyError {
            throw unlockVaultWithNeverlockKeyError
        }
    }
}
