import SwiftUI

// MARK: - TertiaryButtonStyle

/// The style for all tertiary buttons in this application.
///
struct TertiaryButtonStyle: ButtonStyle {
    /// Whether the button is destructive.
    var isDestructive = false

    /// If this button should fill to take up as much width as possible.
    var shouldFillWidth = true

    /// The button's foreground color.
    var foregroundColor: Color {
        isDestructive
            ? Asset.Colors.loadingRed.swiftUIColor
            : Asset.Colors.primaryBitwarden.swiftUIColor
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(foregroundColor)
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .frame(maxWidth: shouldFillWidth ? .infinity : nil)
            .background(Asset.Colors.fillTertiary.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}

// MARK: ButtonStyle

extension ButtonStyle where Self == TertiaryButtonStyle {
    /// The style for all tertiary buttons in this application.
    ///
    /// - Parameters:
    ///   - isDestructive: Whether the button is destructive.
    ///   - shouldFillWidth: A flag indicating if this button should fill all available space.
    ///
    static func tertiary(isDestructive: Bool = false, shouldFillWidth: Bool = true) -> TertiaryButtonStyle {
        TertiaryButtonStyle(isDestructive: isDestructive, shouldFillWidth: shouldFillWidth)
    }
}
