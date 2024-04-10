import Foundation

@testable import AuthenticatorShared

class MockCryptographyService: CryptographyService {
    var encryptError: Error?
    var encryptedAuthenticatorItems = [AuthenticatorItemView]()

    func decrypt(_ authenticatorItem: AuthenticatorItem) async throws -> AuthenticatorItemView {
        AuthenticatorItemView(authenticatorItem: authenticatorItem)
    }

    func encrypt(_ authenticatorItemView: AuthenticatorItemView) async throws -> AuthenticatorItem {
        encryptedAuthenticatorItems.append(authenticatorItemView)
        if let encryptError {
            throw encryptError
        }
        return AuthenticatorItem(authenticatorItemView: authenticatorItemView)
    }
}
