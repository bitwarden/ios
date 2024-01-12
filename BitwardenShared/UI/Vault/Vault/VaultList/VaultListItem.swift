import BitwardenSdk
import Foundation

/// Data model for an item displayed in the vault list.
///
struct VaultListItem: Equatable, Identifiable {
    // MARK: Types

    /// An enumeration for the type of item being displayed by this item.
    enum ItemType: Equatable {
        /// The wrapped item is a cipher.
        case cipher(CipherView)

        /// The wrapped item is a group of items.
        case group(VaultListGroup, Int)

        /// A TOTP Code Item.
        ///
        /// - Parameters
        ///   - name: The name of the Cipher, used for sorting.
        ///   - totpModel: The TOTP model for a cipher.
        ///
        case totp(name: String, totpModel: VaultListTOTP)
    }

    // MARK: Properties

    /// The identifier for the item.
    let id: String

    /// The type of item being displayed by this item.
    let itemType: ItemType
}

extension VaultListItem {
    /// The name of the cipher for TOTP item types, otherwise ""
    ///     Used to sort the TOTP code items after a refresh.
    var name: String {
        guard case let .totp(name, model) = itemType else { return "" }
        return name + (model.loginView.username ?? "") + "\(model.id)"
    }
}

extension VaultListItem {
    /// Initialize a `VaultListItem` from a `CipherView`.
    ///
    /// - Parameter cipherView: The `CipherView` used to initialize the `VaultListItem`.
    ///
    init?(cipherView: CipherView) {
        guard let id = cipherView.id else { return nil }
        self.init(id: id, itemType: .cipher(cipherView))
    }
}

extension VaultListItem {
    /// An image asset for this item that can be used in the UI.
    var icon: ImageAsset {
        switch itemType {
        case let .cipher(cipherItem):
            switch cipherItem.type {
            case .card:
                Asset.Images.creditCard
            case .identity:
                Asset.Images.id
            case .login:
                Asset.Images.globe
            case .secureNote:
                Asset.Images.doc
            }
        case let .group(group, _):
            switch group {
            case .card:
                Asset.Images.creditCard
            case .collection:
                Asset.Images.collections
            case .folder:
                Asset.Images.folderClosed
            case .identity:
                Asset.Images.id
            case .login:
                Asset.Images.globe
            case .secureNote:
                Asset.Images.doc
            case .totp:
                Asset.Images.clock
            case .trash:
                Asset.Images.trash
            }
        case .totp:
            Asset.Images.clock
        }
    }

    /// The login view containing the uri's to download the special decorative icon, if applicable.
    var loginView: BitwardenSdk.LoginView? {
        switch itemType {
        case let .cipher(cipherView):
            cipherView.login
        case .group:
            nil
        case let .totp(_, totpModel):
            totpModel.loginView
        }
    }

    /// The subtitle to show in the row.
    var subtitle: String? {
        switch itemType {
        case let .cipher(cipherView):
            cipherView.subtitle
        case .group:
            nil
        case .totp:
            nil
        }
    }
}

extension CipherView {
    var subtitle: String? {
        switch type {
        case .card:
            var output = [card?.brand]
            if let cardNumber = card?.number,
               cardNumber.count > 4 {
                // Show last 5 characters for amex, last 4 for all others.
                let lastDigitsCount = (cardNumber.count > 5 && cardNumber.contains("^3[47]")) ? 5 : 4
                let displayNumber = "*" + cardNumber.suffix(lastDigitsCount)
                output.append(displayNumber)
            }
            return output.compactMap { $0 }.joined(separator: ", ")
        case .identity:
            return [identity?.firstName, identity?.lastName]
                .compactMap { $0 }
                .joined(separator: " ")
        case .login:
            return login?.username
        case .secureNote:
            return nil
        }
    }
}

struct VaultListTOTP: Equatable {
    /// The id of the associated Cipher.
    ///
    let id: String

    /// The `BitwardenSdk.LoginView` used to populate the view.
    ///
    let loginView: BitwardenSdk.LoginView

    /// The current TOTP code for the cipher.
    ///
    var totpCode: TOTPCode
}
