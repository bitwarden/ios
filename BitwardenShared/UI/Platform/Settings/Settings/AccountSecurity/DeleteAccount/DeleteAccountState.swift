import BitwardenResources

// MARK: - DeleteAccountState

/// An object that defines the current state of a `DeleteAccountView`.
///
struct DeleteAccountState: Equatable {
    // MARK: Properties

    /// A detailed description of the view.
    var description: String {
        if shouldPreventUserFromDeletingAccount {
            Localizations.cannotDeleteAccountDescriptionLong
        } else {
            Localizations.deleteAccountExplanation
        }
    }

    /// The main icon to be displayed.
    var mainIcon: SharedImageAsset {
        if shouldPreventUserFromDeletingAccount {
            SharedAsset.Icons.circleX16
        } else {
            SharedAsset.Icons.warning24
        }
    }

    /// Whether the user should be blocked from deleting their account.
    var shouldPreventUserFromDeletingAccount = false

    /// Whether to show the delete account view buttons.
    var showDeleteAccountButtons: Bool {
        !shouldPreventUserFromDeletingAccount
    }

    /// A short description of the view.
    var title: String {
        if shouldPreventUserFromDeletingAccount {
            Localizations.cannotDeleteAccount
        } else {
            Localizations.deletingYourAccountIsPermanent
        }
    }
}
