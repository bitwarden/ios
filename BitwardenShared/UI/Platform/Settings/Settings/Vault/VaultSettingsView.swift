import BitwardenResources
import SwiftUI

// MARK: - VaultSettingsView

/// A view that allows users to view their vault settings and folders.
///
struct VaultSettingsView: View {
    // MARK: Properties

    /// An action that opens URLs.
    @Environment(\.openURL) private var openURL

    /// The `Store` for this view.
    @ObservedObject var store: Store<VaultSettingsState, VaultSettingsAction, VaultSettingsEffect>

    // MARK: View

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            importLoginsActionCard

            vaultSettings
        }
        .animation(.easeInOut, value: store.state.badgeState?.importLoginsSetupProgress == .complete)
        .scrollView()
        .navigationBar(title: Localizations.vault, titleDisplayMode: .inline)
        .onChange(of: store.state.url) { newValue in
            guard let url = newValue else { return }
            openURL(url)
            store.send(.clearUrl)
        }
        .task {
            await store.perform(.streamSettingsBadge)
        }
    }

    // MARK: Private views

    /// The action card for setting up vault unlock methods.
    @ViewBuilder private var importLoginsActionCard: some View {
        if store.state.shouldShowImportLoginsActionCard {
            ActionCard(
                title: Localizations.importSavedLogins,
                message: Localizations.importSavedLoginsDescriptionLong,
                actionButtonState: ActionCard.ButtonState(title: Localizations.getStarted) {
                    store.send(.showImportLogins)
                },
                dismissButtonState: ActionCard.ButtonState(title: Localizations.dismiss) {
                    await store.perform(.dismissImportLoginsActionCard)
                }
            ) {
                BitwardenBadge(badgeValue: "1")
            }
        }
    }

    /// The vault settings section.
    private var vaultSettings: some View {
        ContentBlock(dividerLeadingPadding: 16) {
            SettingsListItem(Localizations.folders) {
                store.send(.foldersTapped)
            }
            .accessibilityIdentifier("FoldersLabel")

            SettingsListItem(Localizations.exportVault) {
                store.send(.exportVaultTapped)
            }
            .accessibilityIdentifier("ExportVaultLabel")

            SettingsListItem(Localizations.importItems) {
                store.send(.importItemsTapped)
            } trailingContent: {
                Image(asset: Asset.Images.externalLink24)
                    .imageStyle(.rowIcon)
            }
            .accessibilityIdentifier("ImportItemsLinkItemView")
        }
    }
}

#Preview {
    VaultSettingsView(store: Store(processor: StateProcessor(state: VaultSettingsState())))
}
