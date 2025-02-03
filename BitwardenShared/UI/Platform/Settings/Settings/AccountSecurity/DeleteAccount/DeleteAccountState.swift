// MARK: - DeleteAccountState

/// An object that defines the current state of a `DeleteAccountView`.
///
struct DeleteAccountState: Equatable {
    // MARK: Properties

    /// A short description of the view.
    var description: String {
        return if shouldPreventUserFromDeletingAccount {
            Localizations.cannotDeleteAccount
        } else {
            Localizations.deletingYourAccountIsPermanent
        }
    }

    /// A detailed description of the view.
    var longDescription: String {
        return if shouldPreventUserFromDeletingAccount {
            Localizations.cannotDeleteAccountDescriptionLong
        } else {
            Localizations.deleteAccountExplanation
        }
    }

    /// The main icon to be displayed.
    var mainIcon: ImageAsset {
        return if shouldPreventUserFromDeletingAccount {
            Asset.Images.circleX16
        } else {
            Asset.Images.warning24
        }
    }

    /// Whether the form to delete the account is showed.
    var shouldPreventUserFromDeletingAccount = false

    /// Whether to show the delete account view buttons.
    var showDeleteAccountButtons: Bool {
        !shouldPreventUserFromDeletingAccount
    }
}
