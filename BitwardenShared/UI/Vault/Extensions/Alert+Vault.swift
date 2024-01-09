import BitwardenSdk
import UIKit

// MARK: - Alert+Vault

extension Alert {
    /// An alert presenting the user with more options for a vault list item.
    ///
    /// - Parameters:
    ///   - cipherView: The cipher view to show.
    ///   - id: The id of the item.
    ///   - showEdit: Whether to show the edit option (should be `false` for items in the trash).
    ///   - action: The action to perform after selecting an option.
    ///
    /// - Returns: An alert presenting the user with options to select an attachment type.
    @MainActor
    static func moreOptions( // swiftlint:disable:this function_body_length
        cipherView: CipherView,
        id: String,
        showEdit: Bool,
        action: @escaping (_ action: MoreOptionsAction) -> Void
    ) -> Alert {
        // All the cipher types have the option to view the cipher.
        var alertActions = [
            AlertAction(title: Localizations.view, style: .default) { _, _ in action(.view(id: id)) },
        ]

        // Add the option to edit the cipher if desired.
        if showEdit {
            alertActions.append(AlertAction(title: Localizations.edit, style: .default) { _, _ in
                action(.edit(cipherView: cipherView))
            })
        }

        // Add any additional actions for the type of cipher selected.
        switch cipherView.type {
        case .card:
            if let number = cipherView.card?.number {
                alertActions.append(AlertAction(title: Localizations.copyNumber, style: .default) { _, _ in
                    action(.copy(
                        toast: Localizations.number,
                        value: number
                    ))
                })
            }
            if let code = cipherView.card?.code {
                alertActions.append(AlertAction(title: Localizations.copySecurityCode, style: .default) { _, _ in
                    action(.copy(
                        toast: Localizations.securityCode,
                        value: code
                    ))
                })
            }
        case .login:
            if let username = cipherView.login?.username {
                alertActions.append(AlertAction(title: Localizations.copyUsername, style: .default) { _, _ in
                    action(.copy(
                        toast: Localizations.username,
                        value: username
                    ))
                })
            }
            if let password = cipherView.login?.password {
                alertActions.append(AlertAction(title: Localizations.copyPassword, style: .default) { _, _ in
                    action(.copy(
                        toast: Localizations.password,
                        value: password
                    ))
                })
            }
            if let uri = cipherView.login?.uris?.first?.uri,
               let url = URL(string: uri) {
                alertActions
                    .append(AlertAction(title: Localizations.launch, style: .default) { _, _ in
                        action(.launch(url: url))
                    })
            }
        case .identity:
            // TODO: BIT-1364
            // TODO: BIT-1368
            break
        case .secureNote:
            // TODO: BIT-1366
            // TODO: BIT-1375
            break
        }

        // Return the alert.
        return Alert(
            title: cipherView.name,
            message: nil,
            preferredStyle: .actionSheet,
            alertActions: alertActions + [AlertAction(title: Localizations.cancel, style: .cancel)]
        )
    }
}
