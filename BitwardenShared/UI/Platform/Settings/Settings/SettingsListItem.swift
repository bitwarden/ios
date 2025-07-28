import BitwardenResources
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

    /// The optional icon to display on the leading edge of the list item.
    let icon: ImageAsset?

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
                HStack(spacing: 4) {
                    if let icon {
                        Image(asset: icon)
                            .imageStyle(.rowIcon)
                            .padding(.trailing, 8)
                    }

                    Text(name)
                        .styleGuide(.body)
                        .accessibilityIdentifier(nameAccessibilityID ?? "")
                        .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .padding(.vertical, 19)

                    if let badgeValue {
                        BitwardenBadge(badgeValue: badgeValue)
                    }

                    trailingContent()
                        .styleGuide(.body)
                        .foregroundColor(SharedAsset.Colors.textSecondary.swiftUIColor)
                        .multilineTextAlignment(.trailing)
                }
                .padding(.horizontal, icon == nil ? 16 : 12)
            }
        }
        .accessibilityIdentifier(accessibilityIdentifier ?? "")
        .background(SharedAsset.Colors.backgroundSecondary.swiftUIColor)
    }

    // MARK: Initialization

    /// Initializes a new `SettingsListItem`.
    ///
    /// - Parameters:
    ///  - name: The name of the list item.
    ///  - accessibilityIdentifier: The accessibility ID for the list item.
    ///  - badgeValue: An optional string to display as the badge next to the trailing content.
    ///  - icon: The optional icon to display on the leading edge of the list item.
    ///  - nameAccessibilityID: The accessibility ID for the list item name.
    ///  - action: The action to perform when the list item is tapped.
    ///  - trailingContent: Content that appears on the trailing edge of the list item.
    ///
    /// - Returns: The list item.
    ///
    init(
        _ name: String,
        accessibilityIdentifier: String? = nil,
        badgeValue: String? = nil,
        icon: ImageAsset? = nil,
        nameAccessibilityID: String? = nil,
        action: @escaping () -> Void,
        @ViewBuilder trailingContent: @escaping () -> Content? = { EmptyView() }
    ) {
        self.accessibilityIdentifier = accessibilityIdentifier
        self.badgeValue = badgeValue
        self.name = name
        self.icon = icon
        self.nameAccessibilityID = nameAccessibilityID
        self.trailingContent = trailingContent
        self.action = action
    }
}

// MARK: Previews

#if DEBUG
#Preview {
    ScrollView {
        ContentBlock(dividerLeadingPadding: 16) {
            SettingsListItem("Account Security", icon: Asset.Images.locked24) {} trailingContent: {
                Text("Trailing content")
            }

            SettingsListItem("Account Security") {} trailingContent: {
                Image(asset: Asset.Images.externalLink24)
            }

            SettingsListItem("Account Security") {}

            SettingsListItem("Account Security with Badge!", badgeValue: "3") {}

            SettingsListItem("Account Security with Badge!", badgeValue: "4") {} trailingContent: {
                Image(asset: Asset.Images.externalLink24)
            }
        }
    }
    .padding()
    .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
}
#endif
