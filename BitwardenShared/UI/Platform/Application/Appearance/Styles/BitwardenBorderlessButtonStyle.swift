import SwiftUI

// MARK: - BitwardenBorderlessButtonStyle

/// The style for a borderless button in this application.
///
struct BitwardenBorderlessButtonStyle: ButtonStyle {
    // MARK: Properties

    /// A value indicating whether the button is currently enabled or disabled.
    @Environment(\.isEnabled) var isEnabled: Bool

    /// The color of the foreground elements, including text and template images.
    var foregroundColor: Color {
        isEnabled
            ? Asset.Colors.buttonOutlinedForeground.swiftUIColor
            : Asset.Colors.buttonOutlinedDisabledForeground.swiftUIColor
    }

    // MARK: ButtonStyle

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foregroundColor)
            .padding(.vertical, 14)
            .styleGuide(.subheadlineSemibold)
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}

// MARK: ButtonStyle

extension ButtonStyle where Self == BitwardenBorderlessButtonStyle {
    /// The style for a borderless button in this application.
    ///
    static var bitwardenBorderless: BitwardenBorderlessButtonStyle {
        BitwardenBorderlessButtonStyle()
    }
}

// MARK: Previews

#if DEBUG
#Preview() {
    VStack {
        Button("Bitwarden") {}

        Button("Bitwarden") {}
            .disabled(true)
    }
    .buttonStyle(.bitwardenBorderless)
}
#endif
