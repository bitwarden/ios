import SwiftUI

// MARK: - SettingsListItem

/// A list item that appears across settings screens.
///
struct SettingsListItem<Content: View>: View {
    // MARK: Properties

    /// The accessibility ID for the list item.
    let accessibilityIdentifier: String?

    /// The action to perform when the list item is tapped.
    let action: () -> Void

    /// An optional string to display as the badge next to the trailing content.
    let badgeValue: String?

    /// Whether or not the list item should have a divider on the bottom.
    let hasDivider: Bool

    /// The name of the list item.
    let name: String

    /// The accessibility ID for the list item name.
    let nameAccessibilityID: String?

    /// Content that appears on the trailing edge of the list item.
    let trailingContent: () -> Content?

    // MARK: View

    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: 0) {
                HStack {
                    Text(name)
                        .styleGuide(.body)
                        .accessibilityIdentifier(nameAccessibilityID ?? "")
                        .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                        .multilineTextAlignment(.leading)
                        .padding(.vertical, 19)

                    Spacer()

                    if let badgeValue {
                        BitwardenBadge(badgeValue: badgeValue)
                    }

                    trailingContent()
                        .styleGuide(.body)
                        .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                        .multilineTextAlignment(.trailing)
                }
                .padding(.horizontal, 16)

                if hasDivider {
                    Divider()
                        .padding(.leading, 16)
                }
            }
        }
        .accessibilityIdentifier(accessibilityIdentifier ?? "")
        .background(Asset.Colors.backgroundSecondary.swiftUIColor)
    }

    // MARK: Initialization

    /// Initializes a new `SettingsListItem`.
    ///
    /// - Parameters:
    ///  - name: The name of the list item.
    ///  - hasDivider: Whether or not the list item should have a divider on the bottom.
    ///  - accessibilityIdentifier: The accessibility ID for the list item.
    ///  - badgeValue: An optional string to display as the badge next to the trailing content.
    ///  - nameAccessibilityID: The accessibility ID for the list item name.
    ///  - action: The action to perform when the list item is tapped.
    ///  - trailingContent: Content that appears on the trailing edge of the list item.
    ///
    /// - Returns: The list item.
    ///
    init(
        _ name: String,
        hasDivider: Bool = true,
        accessibilityIdentifier: String? = nil,
        badgeValue: String? = nil,
        nameAccessibilityID: String? = nil,
        action: @escaping () -> Void,
        @ViewBuilder trailingContent: @escaping () -> Content? = { EmptyView() }
    ) {
        self.accessibilityIdentifier = accessibilityIdentifier
        self.badgeValue = badgeValue
        self.name = name
        self.hasDivider = hasDivider
        self.nameAccessibilityID = nameAccessibilityID
        self.trailingContent = trailingContent
        self.action = action
    }
}

// MARK: Previews

#if DEBUG
#Preview {
    ScrollView {
        VStack(spacing: 0) {
            SettingsListItem("Account Security") {} trailingContent: {
                Text("Trailing content")
            }

            SettingsListItem("Account Security") {} trailingContent: {
                Image(asset: Asset.Images.externalLink24)
            }

            SettingsListItem("Account Security") {}

            SettingsListItem("Account Security with Badge!", badgeValue: "3") {}
        }
    }
}
#endif
