import AuthenticatorBridgeKit
import BitwardenSdk
import Foundation

/// Data model for an item displayed in the item list.
///
public struct ItemListItem: Equatable, Identifiable {
    // MARK: Types

    /// The type of item being displayed by this item
    public enum ItemType: Equatable {
        /// A TOTP code item that was shared from the Bitwarden PM app.
        ///
        /// - Parameters:
        ///   - model: The TOTP model
        case sharedTotp(model: ItemListSharedTotpItem)

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
    /// A default code to add to the `TOTPCodeModel` when creating a new `ItemListItem`. This code
    /// should be replaced by a legitimate TOTP code by the Processor before it is shown to a user. It is here
    /// so that `code` is non-optional and always has a value.
    private static let defaultTotpCode = "123456"

    /// Initialize an `ItemListItem` from an `AuthenticatorItemView`
    ///
    /// - Parameters:
    ///   - authenticatorItemView: The `AuthenticatorItemView` used to initialize the `ItemListItem`
    ///
    init?(authenticatorItemView: AuthenticatorItemView, timeProvider: TimeProvider) {
        guard let totpKey = TOTPKeyModel(authenticatorKey: authenticatorItemView.totpKey) else { return nil }
        let totpCode = TOTPCodeModel(code: ItemListItem.defaultTotpCode,
                                     codeGenerationDate: timeProvider.presentTime,
                                     period: 30)
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

    /// Initialize an `ItemListItem` from an `AuthenticatorItemView`
    ///
    /// - Parameters:
    ///   - authenticatorItemView: The `AuthenticatorItemView` used to initialize the `ItemListItem`
    ///
    init?(itemView: AuthenticatorBridgeItemDataView, timeProvider: TimeProvider) {
        guard let totpKey = TOTPKeyModel(authenticatorKey: itemView.totpKey) else { return nil }
        let totpCode = TOTPCodeModel(code: ItemListItem.defaultTotpCode,
                                     codeGenerationDate: timeProvider.presentTime,
                                     period: 30)
        let totpModel = ItemListSharedTotpItem(itemView: itemView, totpCode: totpCode)
        let name: String
        let username: String?
        switch totpKey.totpKey {
        case .base32,
             .steamUri:
            name = itemView.name
            username = itemView.username
        case .otpAuthUri:
            name = totpKey.issuer ?? ""
            username = totpKey.accountName
        }

        self.init(id: itemView.id,
                  name: name,
                  accountName: username,
                  itemType: .sharedTotp(model: totpModel))
    }

    /// Make a new `ItemListItem` that is a copy of the existing one, but with an updated `TOTPCodeModel`.
    ///
    /// - Parameter newTotpModel: the new `TOTPCodeModel` to insert in this ItemListItem
    /// - Returns: An exact copy of the data in the existing `ItemListItem`, but with the new
    ///     `TOTPCodeModel` inserted into the itemType's model.
    ///
    public func with(newTotpModel: TOTPCodeModel) -> ItemListItem {
        switch itemType {
        case let .sharedTotp(oldModel):
            var updatedModel = oldModel
            updatedModel.totpCode = newTotpModel
            return ItemListItem(
                id: id,
                name: name,
                accountName: accountName,
                itemType: .sharedTotp(model: updatedModel)
            )
        case let .totp(oldModel):
            var updatedModel = oldModel
            updatedModel.totpCode = newTotpModel
            return ItemListItem(
                id: id,
                name: name,
                accountName: accountName,
                itemType: .totp(model: updatedModel)
            )
        }
    }
}

public struct ItemListTotpItem: Equatable {
    /// The `AuthenticatorItemView` used to populate the view
    let itemView: AuthenticatorItemView

    /// The current TOTP code for the item
    var totpCode: TOTPCodeModel
}

public struct ItemListSharedTotpItem: Equatable {
    /// The `AuthenticatorBridgeItemDataView` used to populate the view
    let itemView: AuthenticatorBridgeItemDataView

    /// The current TOTP code for the item
    var totpCode: TOTPCodeModel
}
