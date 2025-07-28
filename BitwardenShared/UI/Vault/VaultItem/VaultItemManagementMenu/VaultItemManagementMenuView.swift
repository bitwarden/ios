import BitwardenResources
import BitwardenSdk
import SwiftUI

// MARK: - VaultItemManagementMenuView

/// A menu view for displaying options for vault management.
struct VaultItemManagementMenuView: View {
    // MARK: Properties

    /// The flag for showing/hiding clone option.
    let isCloneEnabled: Bool

    /// The flag for whether to show the collections options.
    let isCollectionsEnabled: Bool

    /// The flag for whether to show the delete option.
    let isDeleteEnabled: Bool

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

            if isDeleteEnabled {
                AsyncButton(Localizations.delete, role: .destructive) {
                    await store.perform(.deleteItem)
                }
            }
        } label: {
            Image(asset: Asset.Images.ellipsisVertical24, label: Text(Localizations.options))
                .imageStyle(.toolbarIcon)
        }
        .accessibilityLabel(Localizations.options)
        .frame(minHeight: 44)
    }
}

#Preview {
    VaultItemManagementMenuView(
        isCloneEnabled: true,
        isCollectionsEnabled: true,
        isDeleteEnabled: true,
        isMoveToOrganizationEnabled: true,
        store: Store(
            processor: StateProcessor(
                state: ()
            )
        )
    )
}
