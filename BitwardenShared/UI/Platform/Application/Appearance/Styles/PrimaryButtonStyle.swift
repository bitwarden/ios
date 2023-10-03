import SwiftUI

// MARK: - PrimaryButtonStyle

/// The style for all primary buttons in this application.
///
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled: Bool

    /// If this button should fill to take up as much width as possible.
    var shouldFillWidth = true

    /// The background color of this button.
    var backgroundColor: Color {
        isEnabled
            ? Asset.Colors.primaryBitwarden.swiftUIColor
            : Asset.Colors.fillTertiary.swiftUIColor
    }

    /// The color of the foreground elements in this button, including text and template
    /// images.
    var foregroundColor: Color {
        isEnabled
            ? Asset.Colors.primaryContrastBitwarden.swiftUIColor
            : Asset.Colors.textTertiary.swiftUIColor
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(foregroundColor)
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .frame(maxWidth: shouldFillWidth ? .infinity : nil)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}

// MARK: ButtonStyle

extension ButtonStyle where Self == PrimaryButtonStyle {
    /// The style for all primary buttons in this application.
    ///
    /// - Parameter shouldFillWidth: A flag indicating if this button should fill all available space.
    ///
    static func primary(shouldFillWidth: Bool = true) -> PrimaryButtonStyle {
        PrimaryButtonStyle(shouldFillWidth: shouldFillWidth)
    }
}

// MARK: Previews

struct PrimaryButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        Button("Hello World!") {}
            .buttonStyle(.primary())
            .previewDisplayName("Enabled")

        Button("Hello World!") {}
            .buttonStyle(.primary())
            .disabled(true)
            .previewDisplayName("Disabled")
    }
}
