import SwiftUI

// MARK: - BitwardenButton

/// The standard button used in this application.
///
struct BitwardenButton: View {
    // MARK: Properties

    /// The action that is performed when this button is tapped.
    var action: () -> Void

    /// The background color for this button. Defaults to `.primaryBitwarden`.
    var backgroundColor: Color

    /// The foreground color for this button. Defaults to `.white`.
    var foregroundColor: Color

    /// An optional icon displayed in this button.
    var icon: ImageAsset?

    /// A flag indicating if this button should fill the width of its container.
    var shouldFillWidth = false

    /// The title displayed in this button.
    var title: String

    var body: some View {
        Button(action: action) {
            HStack {
                icon?.swiftUIImage
                Text(title)
            }
            .font(.system(.body))
            .foregroundColor(foregroundColor)
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .frame(maxWidth: shouldFillWidth ? .infinity : nil)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: Initialization

    /// Creates a new `BitwardenButton`.
    ///
    /// - Parameters:
    ///   - title: The title for this button.
    ///   - icon: An optional image to display in this button.
    ///   - backgroundColor: The background color for this button.
    ///   - foregroundColor: The foreground color for this button.
    ///   - shouldFillWidth: A flag indicating if this button should fill the width of its container.
    ///   - action: The action that is performed when this button is tapped.
    init(
        title: String,
        icon: ImageAsset? = nil,
        backgroundColor: Color = Asset.Colors.primaryBitwarden.swiftUIColor,
        foregroundColor: Color = Color.white,
        shouldFillWidth: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.shouldFillWidth = shouldFillWidth
        self.action = action
    }
}
