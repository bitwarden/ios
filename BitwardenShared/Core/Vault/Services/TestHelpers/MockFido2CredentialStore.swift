import BitwardenSdk
import Foundation

@testable import BitwardenShared

class MockFido2CredentialStore: Fido2CredentialStore {
    var findCredentialsResult: Result<[BitwardenSdk.CipherView], Error> = .success([])
    var allCredentialsResult: Result<[BitwardenSdk.CipherListView], Error> = .success([])
    var saveCredentialCalled = false
    var saveCredentialError: (any Error)?

    func findCredentials(ids: [Data]?, ripId: String, userHandle: Data?) async throws -> [BitwardenSdk.CipherView] {
        try findCredentialsResult.get()
    }

    func allCredentials() async throws -> [BitwardenSdk.CipherListView] {
        try allCredentialsResult.get()
    }

    func saveCredential(cred: BitwardenSdk.EncryptionContext) async throws {
        saveCredentialCalled = true
        if let saveCredentialError {
            throw saveCredentialError
        }
    }
}
