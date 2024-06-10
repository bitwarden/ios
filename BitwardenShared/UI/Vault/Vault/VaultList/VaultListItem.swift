import BitwardenSdk
import Foundation

/// Data model for an item displayed in the vault list.
///
public struct VaultListItem: Equatable, Identifiable, VaultItemWithDecorativeIcon {
    // MARK: Types

    /// An enumeration for the type of item being displayed by this item.
    public enum ItemType: Equatable {
        /// The wrapped item is a cipher.
        ///
        /// - Parameters
        ///   - CipherView: The cipher to wrap.
        ///   - asFido2Credential: Whether this cipher item is a Fido2 credential and performs operations as it.
        ///
        case cipher(CipherView, asFido2Credential: Bool = false)

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
    public let id: String

    /// The type of item being displayed by this item.
    public let itemType: ItemType
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

    /// Initialize a `VaultListItem` from a `CipherView`.
    /// - Parameters:
    ///   - cipherView: The `CipherView` used to initialize the `VaultListItem`.
    ///   - asFido2Credential: Whether this item acts as a Fido2 credential.
    init?(cipherView: CipherView, asFido2Credential: Bool) {
        guard let id = cipherView.id, cipherView.type == .login else { return nil }
        self.init(id: id, itemType: .cipher(cipherView, asFido2Credential: asFido2Credential))
    }
}

extension VaultListItem {
    /// The RpId of the main Fido2 credential.
    var fido2CredentialRpId: String? {
        switch itemType {
        case let .cipher(cipherView, asFido2Credential):
            asFido2Credential ? cipherView.mainFido2Credential?.rpId : nil
        case .group:
            nil
        case .totp:
            nil
        }
    }

    /// An image asset for this item that can be used in the UI.
    var icon: ImageAsset {
        switch itemType {
        case let .cipher(cipherItem, asFido2Credential):
            switch cipherItem.type {
            case .card:
                Asset.Images.creditCard
            case .identity:
                Asset.Images.id
            case .login:
                asFido2Credential ? Asset.Images.passkey : Asset.Images.globe
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
            case .noFolder:
                Asset.Images.folderClosed
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

    /// The accessibility ID for the ciphers icon.
    var iconAccessibilityId: String {
        switch itemType {
        case let .cipher(cipherItem, _):
            switch cipherItem.type {
            case .card:
                return "CardCipherIcon"
            case .identity:
                return "IdentityCipherIcon"
            case .login:
                return "LoginCipherIcon"
            case .secureNote:
                return "SecureNoteCipherIcon"
            }
        default:
            return ""
        }
    }

    /// The login view containing the uri's to download the special decorative icon, if applicable.
    var loginView: BitwardenSdk.LoginView? {
        switch itemType {
        case let .cipher(cipherView, _):
            cipherView.login
        case .group:
            nil
        case let .totp(_, totpModel):
            totpModel.loginView
        }
    }

    /// Whether to show or not the Fido2 credential RpId
    var shouldShowFido2CredentialRpId: Bool {
        switch itemType {
        case let .cipher(cipherView, asFido2Credential):
            guard let fido2CredentialRpId, !fido2CredentialRpId.isEmpty else {
                return false
            }
            return asFido2Credential && cipherView.name != fido2CredentialRpId
        case .group:
            return false
        case .totp:
            return false
        }
    }

    /// The subtitle to show in the row.
    var subtitle: String? {
        switch itemType {
        case let .cipher(cipherView, asFido2Credential):
            asFido2Credential ? cipherView.mainFido2CredentialUsername : cipherView.subtitle
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

public struct VaultListTOTP: Equatable {
    /// The id of the associated Cipher.
    ///
    let id: String

    /// The `BitwardenSdk.LoginView` used to populate the view.
    ///
    let loginView: BitwardenSdk.LoginView

    /// Whether seeing the TOTP code requires a master password.
    let requiresMasterPassword: Bool

    /// The current TOTP code for the cipher.
    ///
    var totpCode: TOTPCodeModel
}
