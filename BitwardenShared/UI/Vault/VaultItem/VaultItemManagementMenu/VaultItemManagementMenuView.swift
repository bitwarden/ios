import BitwardenSdk
import SwiftUI

// MARK: - VaultItemManagementMenuView

/// A menu view for displaying options for vault management.
struct VaultItemManagementMenuView: View {
    // MARK: Properties

    /// The flag for showing/hiding clone option
    let isCloneEnabled: Bool

    /// The `Store` for this view.
    @ObservedObject var store: Store<Void, VaultItemManagementMenuAction, VaultItemManagementMenuEffect>

    var body: some View {
        Menu {
            Button(Localizations.attachments) {
                store.send(.attachments)
            }

            if isCloneEnabled {
                Button(Localizations.clone) {
                    store.send(.clone)
                }
            }

            Button(Localizations.moveToOrganization) {
                store.send(.moveToOrganization)
            }

            AsyncButton(Localizations.delete, role: .destructive) {
                await store.perform(.deleteItem)
            }
        } label: {
            Image(asset: Asset.Images.verticalKabob, label: Text(Localizations.options))
                .resizable()
                .frame(width: 19, height: 19)
        }
        .accessibilityLabel(Localizations.options)
    }
}

#Preview {
    VaultItemManagementMenuView(
        isCloneEnabled: true, store: Store(
            processor: StateProcessor(
                state: ()
            )
        )
    )
}
