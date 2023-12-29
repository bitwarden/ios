import BitwardenSdk
import SwiftUI

// MARK: - VaultListItemRowState

/// An object representing the visual state of a `VaultListItemRowView`.
struct VaultListItemRowState {
    // MARK: Properties

    /// The item displayed in this row.
    var item: VaultListItem

    /// A flag indicating if this row should display a divider on the bottom edge.
    var hasDivider: Bool
}

// MARK: - VaultListItemRowAction

/// Actions that can be sent from a `VaultListItemRowView`.
enum VaultListItemRowAction {
    /// The more button was pressed.
    case morePressed
}

// MARK: - VaultListItemRowView

/// A view that displays information about a `VaultListItem` as a row in a list.
struct VaultListItemRowView: View {
    // MARK: Properties

    /// The `Store` for this view.
    var store: Store<VaultListItemRowState, VaultListItemRowAction, Void>

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 16) {
                Image(decorative: store.state.item.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                    .padding(.vertical, 19)

                HStack {
                    switch store.state.item.itemType {
                    case let .cipher(cipherItem):
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(spacing: 8) {
                                Text(cipherItem.name)
                                    .styleGuide(.body)
                                    .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                                    .lineLimit(1)

                                if cipherItem.organizationId != nil {
                                    Asset.Images.collections.swiftUIImage
                                        .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                                }
                            }

                            if let subTitle = cipherItem.subTitle.nilIfEmpty {
                                Text(subTitle)
                                    .styleGuide(.subheadline)
                                    .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                                    .lineLimit(1)
                            }
                        }
                        .accessibilityElement(children: .combine)

                        Spacer()

                        Button {
                            store.send(.morePressed)
                        } label: {
                            Asset.Images.horizontalKabob.swiftUIImage
                        }
                        .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                        .accessibilityLabel(Localizations.more)

                    case let .group(group, count):
                        Text(group.name)
                            .styleGuide(.body)
                            .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                        Spacer()
                        Text("\(count)")
                            .styleGuide(.body)
                            .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                    }
                }
                .padding(.vertical, 9)
            }
            .padding(.horizontal, 16)

            if store.state.hasDivider {
                Divider()
                    .padding(.leading, 22 + 16 + 16)
            }
        }
    }
}
