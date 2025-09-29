import BitwardenResources
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
}
