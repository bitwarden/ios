import SwiftUI

// MARK: - PrimaryButtonStyle

/// The style for all primary buttons in this application.
///
struct PrimaryButtonStyle: ButtonStyle {
    /// If this button should fill to take up as much width as possible.
    var shouldFillWidth = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(Asset.Colors.primaryContrastBitwarden.swiftUIColor)
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .frame(maxWidth: shouldFillWidth ? .infinity : nil)
            .background(Asset.Colors.primaryBitwarden.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}

// MARK: ButtonStyle

extension ButtonStyle where Self == PrimaryButtonStyle {
    /// The style for all primary buttons in this application.
    ///
    /// - Parameter shouldFillWidth: A flag indicating if this button should all available space.
    ///
    static func primary(shouldFillWidth: Bool = true) -> PrimaryButtonStyle {
        PrimaryButtonStyle(shouldFillWidth: shouldFillWidth)
    }
}
