import BitwardenSdk
import Foundation

@testable import BitwardenShared

class MockFido2CredentialStore: Fido2CredentialStore {
    var findCredentialsResult: Result<[BitwardenSdk.CipherView], Error> = .success([])
    var allCredentialsResult: Result<[BitwardenSdk.CipherView], Error> = .success([])
    var saveCredentialCalled = false

    func findCredentials(ids: [Data]?, ripId: String) async throws -> [BitwardenSdk.CipherView] {
        try findCredentialsResult.get()
    }

    func allCredentials() async throws -> [BitwardenSdk.CipherView] {
        try allCredentialsResult.get()
    }

    func saveCredential(cred: BitwardenSdk.Cipher) async throws {
        saveCredentialCalled = true
    }
}
