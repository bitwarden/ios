import SwiftUI

// MARK: - SettingsListItem

/// A list item that appears across settings screens.
///
struct SettingsListItem<Content: View>: View {
    // MARK: Properties

    /// The action to perform when the list item is tapped.
    let action: () -> Void

    /// Whether or not the list item should have a divider on the bottom.
    let hasDivider: Bool

    /// The name of the list item.
    let name: String

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
                        .font(.styleGuide(.body))
                        .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                        .multilineTextAlignment(.leading)
                        .padding(.vertical, 19)

                    Spacer()

                    trailingContent()
                        .font(.styleGuide(.body))
                        .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 16)

                if hasDivider {
                    Divider()
                        .padding(.leading, 16)
                }
            }
        }
        .background(Asset.Colors.backgroundElevatedTertiary.swiftUIColor)
    }

    // MARK: Initialization

    /// Initializes a new `SettingsListItem`.
    ///
    /// - Parameters:
    ///  - name: The name of the list item.
    ///  - hasDivider: Whether or not the list item should have a divider on the bottom.
    ///  - action: The action to perform when the list item is tapped.
    ///  - trailingContent: Content that appears on the trailing edge of the list item.
    ///
    /// - Returns: The list item.
    ///
    init(
        _ name: String,
        hasDivider: Bool = true,
        action: @escaping () -> Void,
        @ViewBuilder trailingContent: @escaping () -> Content? = { EmptyView() }
    ) {
        self.name = name
        self.hasDivider = hasDivider
        self.trailingContent = trailingContent
        self.action = action
    }
}

// MARK: Previews

struct SettingsListItem_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 0) {
                SettingsListItem("Account Security") {} trailingContent: {
                    Text("Trailing content")
                }

                SettingsListItem("Account Security") {} trailingContent: {
                    Image(asset: Asset.Images.externalLink)
                }

                SettingsListItem("Account Security") {}
            }
        }
    }
}
