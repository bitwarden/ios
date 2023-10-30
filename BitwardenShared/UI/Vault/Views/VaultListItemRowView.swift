import BitwardenSdk
import SwiftUI

// MARK: - VaultListItemRowState

/// An object representing the visual state of a `VaultListItemRowView`.
struct VaultListItemRowState {
    /// The item displayed in this row.
    var item: VaultListItem

    /// A flag indicating if this row should display a divider on the bottom edge.
    var hasDivider: Bool

    /// The padding to the top of the view.
    var topPadding: CGFloat {
        switch item.itemType {
        case .cipher:
            return 9
        case .group:
            return 19
        }
    }

    /// The padding between the label and the bottom of the view.
    ///
    /// This value is automatically adjusted for divider display.
    var bottomLabelPadding: CGFloat {
        hasDivider ? (topPadding - 1) : topPadding
    }

    /// The padding between the icon and the bottom of the view.
    var bottomIconPadding: CGFloat {
        topPadding
    }
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
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Image(decorative: store.state.item.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                    .padding(.bottom, store.state.bottomIconPadding)

                VStack(spacing: 0) {
                    HStack {
                        switch store.state.item.itemType {
                        case let .cipher(cipherItem):
                            VStack(alignment: .leading, spacing: 0) {
                                Text(cipherItem.name)
                                    .font(.styleGuide(.body))
                                    .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                                Text(cipherItem.subTitle)
                                    .font(.styleGuide(.subheadline))
                                    .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(cipherItem.name), \(cipherItem.subTitle)")

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
                                .font(.styleGuide(.body))
                                .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                            Spacer()
                            Text("\(count)")
                                .font(.styleGuide(.body))
                                .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                        }
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, store.state.bottomLabelPadding)

                    if store.state.hasDivider {
                        Divider()
                    }
                }
            }
            .padding(.top, store.state.topPadding)
            .padding(.leading, 16)
        }
    }
}
