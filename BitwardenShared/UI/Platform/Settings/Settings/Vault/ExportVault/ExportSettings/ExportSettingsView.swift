import BitwardenResources
import SwiftUI

// MARK: - ExportSettingsView

/// A view that allows users to view choose how to export the vault.
///
struct ExportSettingsView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<Void, ExportSettingsAction, Void>

    // MARK: View

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsListItem(Localizations.exportVaultToAFile) {
                store.send(.exportToFileTapped)
            } trailingContent: {
                chevron
            }
            .accessibilityIdentifier("ExportVaultToAFileLabel")
            .cornerRadius(10)

            SettingsListItem(Localizations.exportVaultToAnotherApp) {
                store.send(.exportToAppTapped)
            } trailingContent: {
                chevron
            }
            .accessibilityIdentifier("ExportVaultToAnotherAppLabel")
            .cornerRadius(10)
        }
        .scrollView()
        .navigationBar(title: Localizations.exportVault, titleDisplayMode: .inline)
    }

    // MARK: Private views

    /// The chevron shown in the settings list item.
    private var chevron: some View {
        Image(asset: Asset.Images.chevronRight16)
            .foregroundColor(Color(asset: SharedAsset.Colors.textSecondary))
    }
}

#Preview {
    ExportSettingsView(store: Store(processor: StateProcessor()))
}
