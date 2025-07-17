import BitwardenResources
import BitwardenSdk
import SwiftUI

// MARK: - SearchVaultFilterRowView

/// A search vault filter row view for displaying options for `VaultFilterType`.
struct SearchVaultFilterRowView: View {
    // MARK: Properties

    /// Whether the row should have a bottom divider.
    let hasDivider: Bool

    /// The accessibility ID for the row.
    let accessibilityID: String?

    /// The `Store` for this view.
    @ObservedObject var store: Store<SearchVaultFilterRowState, SearchVaultFilterRowAction, Void>

    var body: some View {
        if !store.state.vaultFilterOptions.isEmpty {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text(store.state.searchVaultFilterType.filterTitle)
                        .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                        .styleGuide(.body)
                        .accessibilityIdentifier("ActiveFilterNameLabel")

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
                        Asset.Images.ellipsisHorizontal24.swiftUIImage
                            .imageStyle(.rowIcon)
                            .frame(width: 44, height: 44, alignment: .trailing)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel(Localizations.filterByVault)
                    .accessibilityIdentifier("ActiveFilterRow")
                    .foregroundColor(SharedAsset.Colors.textSecondary.swiftUIColor)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .frame(minHeight: 60)
                .background(SharedAsset.Colors.backgroundSecondary.swiftUIColor)

                if hasDivider {
                    Divider()
                }
            }
        }
    }

    // MARK: Initialization

    /// Initialize a `SearchVaultFilterRowView`.
    ///
    /// - Parameters:
    ///   - hasDivider: Whether the row has a divider.
    ///   - accessibilityID: The accessibility ID for the row.
    ///   - store: The store used to render the view.
    ///
    init(
        hasDivider: Bool,
        accessibilityID: String? = nil,
        store: Store<SearchVaultFilterRowState, SearchVaultFilterRowAction, Void>
    ) {
        self.hasDivider = hasDivider
        self.accessibilityID = accessibilityID
        self.store = store
    }
}
