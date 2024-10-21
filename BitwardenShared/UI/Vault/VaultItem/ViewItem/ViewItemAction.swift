@preconcurrency import BitwardenSdk

// MARK: - ViewItemAction

/// Actions that can be processed by a `ViewItemProcessor`.
enum ViewItemAction: Equatable, Sendable {
    /// A card item action
    case cardItemAction(ViewCardItemAction)

    /// A copy button was pressed for the given value.
    ///
    /// - Parameters:
    ///   - value: The value to copy.
    ///   - field: The field being copied.
    ///
    case copyPressed(value: String, field: CopyableField)

    /// The visibility button was pressed for the specified custom field.
    case customFieldVisibilityPressed(CustomFieldState)

    /// The dismiss button was pressed.
    case dismissPressed

    /// The download attachment button was pressed.
    case downloadAttachment(AttachmentView)

    /// The edit button was pressed.
    case editPressed

    /// The more button was pressed.
    case morePressed(VaultItemManagementMenuAction)

    /// The password history button was pressed.
    case passwordHistoryPressed

    /// The password visibility button was pressed.
    case passwordVisibilityPressed

    /// The ssh key item action.
    case sshKeyItemAction(ViewSSHKeyItemAction)

    /// The toast was shown or hidden.
    case toastShown(Toast?)

    /// A flag indicating if this action requires the user to reenter their master password to
    /// complete. This value works hand-in-hand with the `isMasterPasswordRequired` value in
    /// `ViewItemState`.
    var requiresMasterPasswordReprompt: Bool {
        switch self {
        case .cardItemAction,
             .customFieldVisibilityPressed,
             .downloadAttachment,
             .editPressed,
             .morePressed,
             .passwordVisibilityPressed,
             .sshKeyItemAction:
            true
        case let .copyPressed(_, field):
            field.requiresMasterPasswordReprompt
        case .dismissPressed,
             .passwordHistoryPressed,
             .toastShown:
            false
        }
    }
}

// MARK: CopyableField

/// The text fields within the `ViewItemView` that can be copied.
///
enum CopyableField {
    /// The card number field.
    case cardNumber

    /// A custom hidden field.
    case customHiddenField

    /// A custom text field.
    case customTextField

    /// The password field.
    case password

    /// The security code field.
    case securityCode

    /// The key fingerprint of the SSH key item.
    case sshKeyFingerprint

    /// The private key field of an SSH key item.
    case sshPrivateKey

    /// The public key of the SSH key item.
    case sshPublicKey

    /// The totp field.
    case totp

    /// The uri field.
    case uri

    /// The username field.
    case username

    /// The event to collect when copying the field.
    var eventOnCopy: EventType? {
        switch self {
        case .customHiddenField:
            .cipherClientCopiedHiddenField
        case .password:
            .cipherClientCopiedPassword
        case .securityCode:
            .cipherClientCopiedCardCode
        // TODO: PM-11977 add SSH private key copied event
        default:
            nil
        }
    }

    /// Whether copying the field requires the user to be reprompted for their master password, if
    /// master password reprompt is enabled.
    var requiresMasterPasswordReprompt: Bool {
        switch self {
        case .cardNumber,
             .customHiddenField,
             .password,
             .securityCode,
             .sshPrivateKey,
             .totp:
            true
        case .customTextField,
             .sshKeyFingerprint,
             .sshPublicKey,
             .uri,
             .username:
            false
        }
    }

    /// The localized name for each field.
    var localizedName: String? {
        switch self {
        case .cardNumber:
            Localizations.number
        case .customHiddenField,
             .customTextField:
            nil
        case .password:
            Localizations.password
        case .securityCode:
            Localizations.securityCode
        case .sshKeyFingerprint:
            Localizations.fingerprint
        case .sshPrivateKey:
            Localizations.privateKey
        case .sshPublicKey:
            Localizations.publicKey
        case .totp:
            Localizations.totp
        case .uri:
            Localizations.uri
        case .username:
            Localizations.username
        }
    }
}
