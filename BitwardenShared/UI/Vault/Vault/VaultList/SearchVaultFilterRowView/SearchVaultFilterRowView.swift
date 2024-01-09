import BitwardenSdk
import SwiftUI

// MARK: - SearchVaultFilterRowView

/// A search vault filter row view for displaying options for `VaultFilterType`.
struct SearchVaultFilterRowView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<SearchVaultFilterRowState, SearchVaultFilterRowAction, Void>

    var body: some View {
        if !store.state.vaultFilterOptions.isEmpty {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text(store.state.searchVaultFilterType.filterTitle)

                    Spacer()

                    Menu {
                        Picker(selection: store.binding(
                            get: \.searchVaultFilterType,
                            send: SearchVaultFilterRowAction.searchVaultFilterChanged
                        )) {
                            ForEach(store.state.vaultFilterOptions) { filter in
                                Text(filter.title)
                                    .tag(filter)
                            }
                        } label: {
                            EmptyView()
                        }
                    } label: {
                        Asset.Images.horizontalKabob.swiftUIImage
                            .frame(width: 44, height: 44, alignment: .trailing)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel(Localizations.filterByVault)
                    .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                }
                .padding(.horizontal, 16)
                .frame(minHeight: 60)
                .background(Asset.Colors.backgroundPrimary.swiftUIColor)

                Divider()
            }
        }
    }
}
