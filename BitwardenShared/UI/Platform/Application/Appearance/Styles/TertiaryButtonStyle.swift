import SwiftUI

// MARK: - TertiaryButtonStyle

/// The style for all tertiary buttons in this application.
///
struct TertiaryButtonStyle: ButtonStyle {
    /// If this button should fill to take up as much width as possible.
    var shouldFillWidth = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(Asset.Colors.primaryBitwarden.swiftUIColor)
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
    /// - Parameter shouldFillWidth: A flag indicating if this button should fill all available space.
    ///
    static func tertiary(shouldFillWidth: Bool = true) -> TertiaryButtonStyle {
        TertiaryButtonStyle(shouldFillWidth: shouldFillWidth)
    }
}
