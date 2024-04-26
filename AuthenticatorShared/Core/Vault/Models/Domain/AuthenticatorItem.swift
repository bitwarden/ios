import Foundation

/// Data model for an encrypted item
///
struct AuthenticatorItem: Equatable, Sendable {
    let favorite: Bool
    let id: String
    let name: String
    let totpKey: String?
    let username: String?

    init(favorite: Bool, id: String, name: String, totpKey: String?, username: String?) {
        self.favorite = favorite
        self.id = id
        self.name = name
        self.totpKey = totpKey
        self.username = username
    }

    init(itemData: AuthenticatorItemData) throws {
        guard let model = itemData.model else {
            throw DataMappingError.invalidData
        }
        favorite = model.favorite
        id = model.id
        name = model.name
        totpKey = model.totpKey
        username = model.username
    }
}

extension AuthenticatorItem {
    static func fixture(
        favorite: Bool = false,
        id: String = "ID",
        name: String = "Example",
        totpKey: String? = "example",
        username: String? = "person@example.com"
    ) -> AuthenticatorItem {
        AuthenticatorItem(
            favorite: favorite,
            id: id,
            name: name,
            totpKey: totpKey,
            username: username
        )
    }
}

/// Data model for an unencrypted item
///
public struct AuthenticatorItemView: Equatable, Sendable, Hashable, Codable {
    let favorite: Bool
    let id: String
    let name: String
    let totpKey: String?
    let username: String?
}

extension AuthenticatorItemView {
    static func fixture(
        favorite: Bool = false,
        id: String = "ID",
        name: String = "Example",
        totpKey: String? = "example",
        username: String? = "person@example.com"
    ) -> AuthenticatorItemView {
        AuthenticatorItemView(
            favorite: favorite,
            id: id,
            name: name,
            totpKey: totpKey,
            username: username
        )
    }
}
