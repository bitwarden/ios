import BitwardenKit
import BitwardenResources
import BitwardenSdk
import SwiftUI

// MARK: - VaultItemManagementMenuView

/// A menu view for displaying options for vault management.
struct VaultItemManagementMenuView: View {
    // MARK: Properties

    /// The flag for whether to show the archive option.
    let isArchiveEnabled: Bool

    /// The flag for showing/hiding clone option.
    let isCloneEnabled: Bool

    /// The flag for whether to show the collections options.
    let isCollectionsEnabled: Bool

    /// The flag for whether to show the delete option.
    let isDeleteEnabled: Bool

    /// The flag for whether to show the move to organization options.
    let isMoveToOrganizationEnabled: Bool

    /// The flag for whether to show the restore option.
    let isRestoreEnabled: Bool

    /// The flag for whether to show the unarchive option.
    let isUnarchiveEnabled: Bool

    /// The `Store` for this view.
    @ObservedObject var store: Store<Void, VaultItemManagementMenuAction, VaultItemManagementMenuEffect>

    var body: some View {
        Menu {
            if isRestoreEnabled {
                Button(Localizations.restore) {
                    store.send(.restore)
                }
                .accessibilityIdentifier("RestoreButton")
            }

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

            if isArchiveEnabled {
                AsyncButton(Localizations.archive) {
                    await store.perform(.archiveItem)
                }
                .accessibilityIdentifier("ArchiveButton")
            } else if isUnarchiveEnabled {
                AsyncButton(Localizations.unarchive) {
                    await store.perform(.unarchiveItem)
                }
                .accessibilityIdentifier("UnarchiveButton")
            }

            if isDeleteEnabled {
                AsyncButton(Localizations.delete, role: .destructive) {
                    await store.perform(.deleteItem)
                }
            }
        } label: {
            Image(asset: SharedAsset.Icons.ellipsisVertical24, label: Text(Localizations.options))
                .imageStyle(.toolbarIcon)
        }
        .accessibilityLabel(Localizations.options)
        .frame(minHeight: 44)
    }
}

#Preview {
    VaultItemManagementMenuView(
        isArchiveEnabled: true,
        isCloneEnabled: true,
        isCollectionsEnabled: true,
        isDeleteEnabled: true,
        isMoveToOrganizationEnabled: true,
        isRestoreEnabled: true,
        isUnarchiveEnabled: false,
        store: Store(
            processor: StateProcessor(
                state: (),
            ),
        ),
    )
}
