import SwiftUI

// MARK: - SecondaryButtonStyle

/// The style for all secondary buttons in this application.
///
struct SecondaryButtonStyle: ButtonStyle {
    /// If this button should fill to take up as much width as possible.
    var shouldFillWidth = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(Asset.Colors.primaryBitwarden.swiftUIColor)
            .styleGuide(.bodyBold)
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .frame(maxWidth: shouldFillWidth ? .infinity : nil)
            .background(Asset.Colors.primaryBitwarden.swiftUIColor.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}

// MARK: ButtonStyle

extension ButtonStyle where Self == SecondaryButtonStyle {
    /// The style for all secondary buttons in this application.
    ///
    /// - Parameter shouldFillWidth: A flag indicating if this button should fill all available space.
    ///
    static func secondary(shouldFillWidth: Bool = true) -> SecondaryButtonStyle {
        SecondaryButtonStyle(shouldFillWidth: shouldFillWidth)
    }
}
