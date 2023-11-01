import BitwardenSdk
import SwiftUI

// MARK: - VaultListItemRowState

/// An object representing the visual state of a `VaultListItemRowView`.
struct VaultListItemRowState {
    // MARK: Static Properties

    /// The padding above an element containing one text element.
    private static let singleTextTopPadding: CGFloat = 19

    /// The padding above an element containing two text elements.
    private static let doubleTextTopPadding: CGFloat = 9

    // MARK: Properties

    /// The padding between the icon and the bottom of the view.
    var bottomIconPadding: CGFloat {
        topPadding
    }

    /// The padding between the label and the bottom of the view.
    ///
    /// This value is automatically adjusted for divider display.
    var bottomLabelPadding: CGFloat {
        hasDivider ? (topPadding - 1) : topPadding
    }

    /// A flag indicating if this row should display a divider on the bottom edge.
    var hasDivider: Bool

    /// The item displayed in this row.
    var item: VaultListItem

    /// The padding to the top of the view.
    var topPadding: CGFloat {
        switch item.itemType {
        case let .cipher(cipherItem):
            if cipherItem.subTitle.isEmpty {
                return Self.singleTextTopPadding
            } else {
                return Self.doubleTextTopPadding
            }
        case .group:
            return Self.singleTextTopPadding
        }
    }

    /// Creates a new `VaultListItemRowState` object.
    ///
    /// - Parameters:
    ///   - item: The item displayed in this row.
    ///   - hasDivider: A flag indicating if this row should display a divider on the bottom edge.
    ///
    init(item: VaultListItem, hasDivider: Bool) {
        self.hasDivider = hasDivider
        self.item = item
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
                                if let subTitle = cipherItem.subTitle.nilIfEmpty {
                                    Text(subTitle)
                                        .font(.styleGuide(.subheadline))
                                        .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
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
