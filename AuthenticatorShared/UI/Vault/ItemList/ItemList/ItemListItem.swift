import BitwardenSdk
import Foundation

/// Data model for an item displayed in the item list.
///
public struct ItemListItem: Equatable, Identifiable {
    // MARK: Types

    /// The type of item being displayed by this item
    public enum ItemType: Equatable {
        /// A TOTP code item
        ///
        /// - Parameters:
        ///   - model: The TOTP model
        case totp(model: ItemListTotpItem)
    }

    /// The identifier for the item.
    public let id: String

    /// The name to display for the item.
    public let name: String

    /// The account name of the item.
    public let accountName: String?

    /// The type of item being displayed by this item
    public let itemType: ItemType
}

extension ItemListItem {
    /// Initialize an `ItemListItem` from an `AuthenticatorItemView`
    ///
    /// - Parameters:
    ///   - authenticatorItemView: The `AuthenticatorItemView` used to initialize the `ItemListItem`
    ///
    init?(authenticatorItemView: AuthenticatorItemView) {
        guard let totpKey = TOTPKeyModel(authenticatorKey: authenticatorItemView.totpKey) else { return nil }
        let totpCode = TOTPCodeModel(code: "123456", codeGenerationDate: .now, period: 30)
        let totpModel = ItemListTotpItem(itemView: authenticatorItemView, totpCode: totpCode)
        let name: String
        let username: String?
        switch totpKey.totpKey {
        case .base32,
             .steamUri:
            name = authenticatorItemView.name
            username = authenticatorItemView.username
        case .otpAuthUri:
            name = totpKey.issuer ?? ""
            username = totpKey.accountName
        }

        self.init(id: authenticatorItemView.id,
                  name: name,
                  accountName: username,
                  itemType: .totp(model: totpModel))
    }
}

public struct ItemListTotpItem: Equatable {
    /// The `AuthenticatorItemView` used to populate the view
    let itemView: AuthenticatorItemView

    /// The current TOTP code for the item
    var totpCode: TOTPCodeModel
}
