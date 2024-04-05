import BitwardenSdk
import Foundation

/// Data model for an item displayed in the item list.
///
public struct ItemListItem: Equatable, Identifiable {
    /// The identifier for the item.
    public let id: String

    /// The name to display for the item.
    public let name: String

    /// The token used to generate the code.
    public let token: Token

    /// The current TOTP code for the ciper.
    public var totpCode: TOTPCodeModel
}
