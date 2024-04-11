import UIKit

// MARK: Alert+Vault

extension Alert {
    /// An alert confirming deletion of an item
    ///
    /// - Parameters:
    ///   - action: The action to perform if the user confirms
    /// - Returns: An alert confirming item deletion
    ///
    static func confirmDeleteItem(action: @escaping () async -> Void) -> Alert {
        Alert(
            title: Localizations.doYouReallyWantToDelete,
            message: nil,
            alertActions: [
                AlertAction(title: Localizations.yes, style: .default) { _, _ in await action() },
                AlertAction(title: Localizations.no, style: .cancel),
            ]
        )
    }

    /// An alert presenting the user with more options for an item.
    ///
    /// - Parameters:
    ///   - authenticatorItemView: The item to show
    ///   - id: The id of the item
    ///   - action: The action to perform after selecting an option.
    ///
    /// - Returns: An alert presenting the user with options to select an attachment type.
    @MainActor
    static func moreOptions(
        authenticatorItemView: AuthenticatorItemView,
        id: String,
        action: @escaping (_ action: MoreOptionsAction) async -> Void
    ) -> Alert {
        var alertActions = [AlertAction]()

        if let totp = authenticatorItemView.totpKey,
           let totpKey = TOTPKeyModel(authenticatorKey: totp) {
            alertActions.append(
                AlertAction(title: Localizations.copy, style: .default) { _, _ in
                    await action(.copyTotp(totpKey: totpKey))
                })
        }

        alertActions.append(AlertAction(title: Localizations.edit, style: .default) { _, _ in
            await action(.edit(authenticatorItemView: authenticatorItemView))
        })

        alertActions.append(AlertAction(title: Localizations.delete, style: .destructive) { _, _ in
            await action(.delete(id: id))
        })

        return Alert(
            title: authenticatorItemView.name,
            message: nil,
            preferredStyle: .actionSheet,
            alertActions: alertActions + [AlertAction(title: Localizations.cancel, style: .cancel)]
        )
    }
}
