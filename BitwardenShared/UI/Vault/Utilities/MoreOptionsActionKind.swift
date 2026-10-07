import BitwardenResources
import BitwardenSdk
import Foundation

// MARK: - MoreOptionsActionKind

/// The kind of an individual more-options action for a vault list item, independent of the
/// concrete cipher values needed to actually perform it.
///
/// This is the single source of truth for which more-options actions exist. The available kinds for
/// a cipher are computed from its `CipherListView` (see `CipherListView.applicableMoreOptionsActionKinds`)
/// and are used both to build the more-options action sheet and the vault list row's VoiceOver
/// custom accessibility actions.
///
enum MoreOptionsActionKind: CaseIterable, Equatable {
    /// Archive the cipher.
    case archive

    /// Copy the cipher's bank account number.
    case copyAccountNumber

    /// Copy the cipher's card number.
    case copyCardNumber

    /// Copy the cipher's SSH key fingerprint.
    case copyFingerprint

    /// Copy the cipher's drivers license number.
    case copyLicenseNumber

    /// Copy the cipher's notes.
    case copyNotes

    /// Copy the cipher's passport number.
    case copyPassportNumber

    /// Copy the cipher's password.
    case copyPassword

    /// Copy the cipher's SSH private key.
    case copyPrivateKey

    /// Copy the cipher's SSH public key.
    case copyPublicKey

    /// Copy the cipher's bank account routing number.
    case copyRoutingNumber

    /// Copy the cipher's security code.
    case copySecurityCode

    /// Copy the cipher's TOTP code.
    case copyTotp

    /// Copy the cipher's username.
    case copyUsername

    /// Navigate to edit the cipher.
    case edit

    /// Launch the cipher's URI.
    case launch

    /// Unarchive the cipher.
    case unarchive

    /// Navigate to view the cipher.
    case view

    /// The localized display name for this action. Used both as the action sheet's `AlertAction`
    /// title and as the row's `.accessibilityAction` name, so VoiceOver announces the same words
    /// a sighted user reads in the sheet.
    var localizedName: String {
        switch self {
        case .archive: Localizations.archive
        case .copyAccountNumber: Localizations.copyAccountNumber
        case .copyCardNumber: Localizations.copyNumber
        case .copyFingerprint: Localizations.copyFingerprint
        case .copyLicenseNumber: Localizations.copyLicenseNumber
        case .copyNotes: Localizations.copyNotes
        case .copyPassportNumber: Localizations.copyPassportNumber
        case .copyPassword: Localizations.copyPassword
        case .copyPrivateKey: Localizations.copyPrivateKey
        case .copyPublicKey: Localizations.copyPublicKey
        case .copyRoutingNumber: Localizations.copyRoutingNumber
        case .copySecurityCode: Localizations.copySecurityCode
        case .copyTotp: Localizations.copyTotp
        case .copyUsername: Localizations.copyUsername
        case .edit: Localizations.edit
        case .launch: Localizations.launch
        case .unarchive: Localizations.unarchive
        case .view: Localizations.view
        }
    }

    /// Maps this kind and a concrete cipher to the fully-parameterized `MoreOptionsAction` to
    /// execute.
    ///
    /// - Parameters:
    ///   - cipherView: The cipher to act upon.
    ///   - itemId: The id of the vault list item, used for the `.view` action.
    /// - Returns: The action to execute, or `nil` if the expected field is unexpectedly missing or
    ///   the cipher doesn't allow viewing its password (defensive only — the action shouldn't have
    ///   been offered in that case).
    func moreOptionsAction( // swiftlint:disable:this cyclomatic_complexity function_body_length
        cipherView: CipherView,
        itemId: String,
    ) -> MoreOptionsAction? {
        switch self {
        case .archive:
            return .archive(cipherView: cipherView)
        case .copyAccountNumber:
            guard let accountNumber = cipherView.bankAccount?.accountNumber else { return nil }
            return .copy(
                toast: Localizations.accountNumber,
                value: accountNumber,
                requiresMasterPasswordReprompt: true,
                logEvent: nil,
                cipherId: nil,
            )
        case .copyCardNumber:
            guard let number = cipherView.card?.number else { return nil }
            return .copy(
                toast: Localizations.number,
                value: number,
                requiresMasterPasswordReprompt: true,
                logEvent: nil,
                cipherId: nil,
            )
        case .copyFingerprint:
            guard let sshKey = cipherView.sshKey else { return nil }
            return .copy(
                toast: Localizations.fingerprint,
                value: sshKey.fingerprint,
                requiresMasterPasswordReprompt: true,
                logEvent: nil,
                cipherId: cipherView.id,
            )
        case .copyLicenseNumber:
            guard let licenseNumber = cipherView.driversLicense?.licenseNumber else { return nil }
            return .copy(
                toast: Localizations.licenseNumber,
                value: licenseNumber,
                requiresMasterPasswordReprompt: true,
                logEvent: nil,
                cipherId: cipherView.id,
            )
        case .copyNotes:
            guard let notes = cipherView.notes else { return nil }
            return .copy(
                toast: Localizations.notes,
                value: notes,
                requiresMasterPasswordReprompt: true,
                logEvent: nil,
                cipherId: nil,
            )
        case .copyPassportNumber:
            guard let passportNumber = cipherView.passport?.passportNumber else { return nil }
            return .copy(
                toast: Localizations.passportNumber,
                value: passportNumber,
                requiresMasterPasswordReprompt: true,
                logEvent: nil,
                cipherId: cipherView.id,
            )
        case .copyPassword:
            guard let password = cipherView.login?.password, cipherView.viewPassword else { return nil }
            return .copy(
                toast: Localizations.password,
                value: password,
                requiresMasterPasswordReprompt: true,
                logEvent: .cipherClientCopiedPassword,
                cipherId: cipherView.id,
            )
        case .copyPrivateKey:
            guard let sshKey = cipherView.sshKey, cipherView.viewPassword else { return nil }
            return .copy(
                toast: Localizations.privateKey,
                value: sshKey.privateKey,
                requiresMasterPasswordReprompt: true,
                logEvent: nil,
                cipherId: cipherView.id,
            )
        case .copyPublicKey:
            guard let sshKey = cipherView.sshKey else { return nil }
            return .copy(
                toast: Localizations.publicKey,
                value: sshKey.publicKey,
                requiresMasterPasswordReprompt: true,
                logEvent: nil,
                cipherId: cipherView.id,
            )
        case .copyRoutingNumber:
            guard let routingNumber = cipherView.bankAccount?.routingNumber else { return nil }
            return .copy(
                toast: Localizations.routingNumber,
                value: routingNumber,
                requiresMasterPasswordReprompt: true,
                logEvent: nil,
                cipherId: nil,
            )
        case .copySecurityCode:
            guard let code = cipherView.card?.code else { return nil }
            return .copy(
                toast: Localizations.securityCode,
                value: code,
                requiresMasterPasswordReprompt: true,
                logEvent: .cipherClientCopiedCardCode,
                cipherId: cipherView.id,
            )
        case .copyTotp:
            guard let totp = cipherView.login?.totp else { return nil }
            return .copyTotp(totpKey: TOTPKeyModel(authenticatorKey: totp))
        case .copyUsername:
            guard let username = cipherView.login?.username else { return nil }
            return .copy(
                toast: Localizations.username,
                value: username,
                requiresMasterPasswordReprompt: false,
                logEvent: nil,
                cipherId: nil,
            )
        case .edit:
            return .edit(cipherView: cipherView)
        case .launch:
            guard let uri = cipherView.login?.uris?.first?.uri, let url = URL(string: uri) else { return nil }
            return .launch(url: url)
        case .unarchive:
            return .unarchive(cipherView: cipherView)
        case .view:
            return .view(id: itemId)
        }
    }
}

// MARK: - CipherListView

extension CipherListView {
    /// Computes, synchronously and without decrypting anything beyond what's already in this
    /// list view, the set of more-options actions applicable to this cipher. Used to build the
    /// more-options action sheet and to populate the vault list row's VoiceOver custom
    /// accessibility actions without a `fetchCipher` round trip.
    ///
    /// Scope note: this is the full set of more-options actions offered (e.g. no Identity fields,
    /// no bank IBAN/SWIFT/PIN/branch number), even though `copyableFields` exposes more than is
    /// currently surfaced.
    ///
    /// - Parameter hasPremium: Whether the active account has Premium, used to gate the Copy TOTP
    ///   action.
    /// - Returns: The list of applicable more-options action kinds, in the order they should be
    ///   presented.
    func applicableMoreOptionsActionKinds( // swiftlint:disable:this cyclomatic_complexity
        hasPremium: Bool,
    ) -> [MoreOptionsActionKind] {
        guard !isDecryptionFailure else { return [] }

        var kinds: [MoreOptionsActionKind] = [.view]
        if deletedDate == nil { kinds.append(.edit) }

        switch type {
        case .card:
            if copyableFields.contains(.cardNumber) { kinds.append(.copyCardNumber) }
            if copyableFields.contains(.cardSecurityCode) { kinds.append(.copySecurityCode) }
        case let .login(loginListView):
            if copyableFields.contains(.loginUsername) { kinds.append(.copyUsername) }
            if copyableFields.contains(.loginPassword), viewPassword { kinds.append(.copyPassword) }
            if copyableFields.contains(.loginTotp), hasPremium || organizationUseTotp {
                kinds.append(.copyTotp)
            }
            if let uri = loginListView.uris?.first?.uri, URL(string: uri) != nil {
                kinds.append(.launch)
            }
        case .identity:
            break
        case .secureNote:
            if copyableFields.contains(.secureNotes) { kinds.append(.copyNotes) }
        case .sshKey:
            if copyableFields.contains(.sshKey) {
                kinds.append(.copyPublicKey)
                if viewPassword { kinds.append(.copyPrivateKey) }
                kinds.append(.copyFingerprint)
            }
        case .bankAccount:
            if copyableFields.contains(.bankAccountAccountNumber) { kinds.append(.copyAccountNumber) }
            if copyableFields.contains(.bankAccountRoutingNumber) { kinds.append(.copyRoutingNumber) }
        case .driversLicense:
            if copyableFields.contains(.driversLicenseLicenseNumber) { kinds.append(.copyLicenseNumber) }
        case .passport:
            if copyableFields.contains(.passportPassportNumber) { kinds.append(.copyPassportNumber) }
        }

        if canBeArchived { kinds.append(.archive) }
        if canBeUnarchived { kinds.append(.unarchive) }
        return kinds
    }
}
