import BitwardenSdk
import SwiftUI

// MARK: - VaultItemManagementMenuView

/// A menu view for displaying options for vault management.
struct VaultItemManagementMenuView: View {
    // MARK: Properties

    /// The flag for showing/hiding clone option
    let isCloneEnabled: Bool

    /// The flag for whether to show the collections options.
    let isCollectionsEnabled: Bool

    /// The flag for whether to show the move to organization options.
    let isMoveToOrganizationEnabled: Bool

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

            if isCollectionsEnabled {
                Button(Localizations.collections) {
                    store.send(.editCollections)
                }
            }

            if isMoveToOrganizationEnabled {
                Button(Localizations.moveToOrganization) {
                    store.send(.moveToOrganization)
                }
            }

            AsyncButton(Localizations.delete, role: .destructive) {
                await store.perform(.deleteItem)
            }
        } label: {
            Image(asset: Asset.Images.verticalKabob, label: Text(Localizations.options))
                .resizable()
                .frame(width: 19, height: 19)
                .foregroundColor(Asset.Colors.primaryBitwarden.swiftUIColor)
        }
        .accessibilityLabel(Localizations.options)
    }
}

#Preview {
    VaultItemManagementMenuView(
        isCloneEnabled: true,
        isCollectionsEnabled: true,
        isMoveToOrganizationEnabled: true,
        store: Store(
            processor: StateProcessor(
                state: ()
            )
        )
    )
}
