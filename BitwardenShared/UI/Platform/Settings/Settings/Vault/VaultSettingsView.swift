import SwiftUI

// MARK: - VaultSettingsView

/// A view that allows users to view their vault settings and folders.
///
struct VaultSettingsView: View {
    // MARK: Properties

    /// An action that opens URLs.
    @Environment(\.openURL) private var openURL

    /// The `Store` for this view.
    @ObservedObject var store: Store<VaultSettingsState, VaultSettingsAction, Void>

    // MARK: View

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            vaultSettings
        }
        .scrollView()
        .navigationBar(title: Localizations.vault, titleDisplayMode: .inline)
        .onChange(of: store.state.url) { newValue in
            guard let url = newValue else { return }
            openURL(url)
            store.send(.clearUrl)
        }
    }

    // MARK: Private views

    /// The vault settings section.
    private var vaultSettings: some View {
        VStack(spacing: 0) {
            SettingsListItem(Localizations.folders) {
                store.send(.foldersTapped)
            }
            .accessibilityIdentifier("FoldersLabel")

            SettingsListItem(Localizations.exportVault) {
                store.send(.exportVaultTapped)
            }
            .accessibilityIdentifier("ExportVaultLabel")

            SettingsListItem(Localizations.importItems, hasDivider: false) {
                store.send(.importItemsTapped)
            } trailingContent: {
                Image(asset: Asset.Images.externalLink2)
                    .resizable()
                    .frame(width: 22, height: 22)
            }
            .accessibilityIdentifier("ImportItemsLinkItemView")
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    VaultSettingsView(store: Store(processor: StateProcessor(state: VaultSettingsState())))
}
