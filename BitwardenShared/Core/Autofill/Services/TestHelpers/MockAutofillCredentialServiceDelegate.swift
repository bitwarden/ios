@testable import BitwardenShared

class MockAutofillCredentialServiceDelegate: AutofillCredentialServiceDelegate {
    var unlockVaultWithNeverlockKeyCalled = false
    var unlockVaultWithNeverlockKeyError: Error?

    func unlockVaultWithNeverlockKey() async throws {
        unlockVaultWithNeverlockKeyCalled = true
        if let unlockVaultWithNeverlockKeyError {
            throw unlockVaultWithNeverlockKeyError
        }
    }
}
