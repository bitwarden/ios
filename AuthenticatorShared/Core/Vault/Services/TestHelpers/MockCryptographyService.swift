import Foundation

@testable import AuthenticatorShared

class MockCryptographyService: CryptographyService {
    var decryptError: Error?
    var decryptedAuthenticatorItems = [AuthenticatorItem]()

    var encryptError: Error?
    var encryptedAuthenticatorItems = [AuthenticatorItemView]()

    func decrypt(_ authenticatorItem: AuthenticatorItem) async throws -> AuthenticatorItemView {
        decryptedAuthenticatorItems.append(authenticatorItem)
        if let decryptError {
            throw decryptError
        }
        return AuthenticatorItemView(authenticatorItem: authenticatorItem)
    }

    func encrypt(_ authenticatorItemView: AuthenticatorItemView) async throws -> AuthenticatorItem {
        encryptedAuthenticatorItems.append(authenticatorItemView)
        if let encryptError {
            throw encryptError
        }
        return AuthenticatorItem(authenticatorItemView: authenticatorItemView)
    }
}
