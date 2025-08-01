import BitwardenResources
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

    /// The view item disappeared from the screen.
    case disappeared

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

    /// The identity name field.
    case identityName

    /// The company field.
    case company

    /// The social security number field.
    case socialSecurityNumber

    /// The passport number field.
    case passportNumber

    /// The license number field.
    case licenseNumber

    /// The email field.
    case email

    /// The identity phone field.
    case phone

    /// The identity address field.
    case fullAddress

    /// The notes field.
    case notes

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
            Localizations.websiteURI
        case .username:
            Localizations.username
        case .identityName:
            Localizations.identityName
        case .company:
            Localizations.company
        case .socialSecurityNumber:
            Localizations.ssn
        case .passportNumber:
            Localizations.passportNumber
        case .licenseNumber:
            Localizations.licenseNumber
        case .email:
            Localizations.email
        case .phone:
            Localizations.phone
        case .fullAddress:
            Localizations.address
        case .notes:
            Localizations.notes
        }
    }
}
