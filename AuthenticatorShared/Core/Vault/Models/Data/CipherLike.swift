import Foundation

// MARK: - CipherLike

/// A data model used to export/import authenticator items in a way that resembles
/// `Cipher` objects
///
struct CipherLike: Codable, Equatable {
    let id: String
    let name: String
    let folderId: String?
    let organizationId: String?
    let collectionIds: [String]?
    let notes: String?
    let type: Int
    let login: LoginLike?
    let favorite: Bool

    init?(_ item: AuthenticatorItemView) {
        id = item.id
        name = item.name
        folderId = nil
        organizationId = nil
        collectionIds = nil
        notes = nil
        type = 1
        favorite = item.favorite
        login = LoginLike(item)
    }
}

// MARK: - LoginLike

/// A data model used to export/import authenticator items in a way that resembles
/// the `Login` part of a `Cipher` object.
///
struct LoginLike: Codable, Equatable {
    let totp: String?
    let username: String?

    init?(_ item: AuthenticatorItemView) {
        guard let key = TOTPKeyModel(authenticatorKey: item.totpKey)
        else { return nil }
        totp = key.rawAuthenticatorKey
        username = key.accountName?.nilIfEmpty ?? item.username?.nilIfEmpty
    }
}

// MARK: VaultLike

/// A data model used to export/import authenticator items in a way that resembles
/// a full vault export/import from the PM app.
///
struct VaultLike: Codable, Equatable {
    let encrypted: Bool
    let items: [CipherLike]
}
