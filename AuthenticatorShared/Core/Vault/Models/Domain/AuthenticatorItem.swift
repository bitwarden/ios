import Foundation

/// Data model for an encrypted item
///
struct AuthenticatorItem: Equatable, Sendable {
    let id: String
    let name: String
    let totpKey: String?

    init(id: String, name: String, totpKey: String?) {
        self.id = id
        self.name = name
        self.totpKey = totpKey
    }

    init(itemData: AuthenticatorItemData) throws {
        guard let model = itemData.model else {
            throw DataMappingError.invalidData
        }
        id = model.id
        name = model.name
        totpKey = model.totpKey
    }
}

extension AuthenticatorItem {
    static func fixture(
        id: String = "ID",
        name: String = "Example",
        totpKey: String? = "example"
    ) -> AuthenticatorItem {
        AuthenticatorItem(
            id: id,
            name: name,
            totpKey: totpKey
        )
    }
}

/// Data model for an unencrypted item
///
public struct AuthenticatorItemView: Equatable, Sendable, Hashable, Codable {
    let id: String
    let name: String
    let totpKey: String?
}

extension AuthenticatorItemView {
    static func fixture(
        id: String = "ID",
        name: String = "Example",
        totpKey: String? = "example"
    ) -> AuthenticatorItemView {
        AuthenticatorItemView(
            id: id,
            name: name,
            totpKey: totpKey
        )
    }
}
