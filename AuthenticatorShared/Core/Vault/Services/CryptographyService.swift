import Foundation

// MARK: - CryptographyService

/// A protocol for a `CryptographyService` which manages encrypting and decrypting `AuthenticationItem` objects
///
protocol CryptographyService {
    func encrypt(_ authenticatorItemView: AuthenticatorItemView) async throws -> AuthenticatorItem

    func decrypt(_ authenticatorItem: AuthenticatorItem) async throws -> AuthenticatorItemView
}

// TODO: Actually encrypt/decrypt the item
class DefaultCryptographyService: CryptographyService {
    func encrypt(_ authenticatorItemView: AuthenticatorItemView) async throws -> AuthenticatorItem {
        AuthenticatorItem(
            id: authenticatorItemView.id,
            name: authenticatorItemView.name,
            totpKey: authenticatorItemView.totpKey
        )
    }

    func decrypt(_ authenticatorItem: AuthenticatorItem) async throws -> AuthenticatorItemView {
        AuthenticatorItemView(
            id: authenticatorItem.id,
            name: authenticatorItem.name,
            totpKey: authenticatorItem.totpKey
        )
    }
}
